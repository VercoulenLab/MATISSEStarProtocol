library(tiff)
library(dplyr)
library(stringr)
library(doParallel)

# For parallel processing define number of aviable cores
#aviablecores <- 8
#registerDoParallel(cores = aviablecores)

str_escape_plus <- function(string){
  string <- str_replace(string, "\\+", "\\\\+")
  return(string)
}

# The root folder where all data is located
projectpath <- "/"
outputfile <- paste0(projectpath, "SingleCellData-MATISSE.Rda")

# Path of RAW data
PathRawData <- paste0(projectpath, "IMC-Data/")

# Folder where segmentation maps are located
Segmentationpath <- paste0(projectpath, "SegmentationMaps/Objects/")

# Naming convention of segmentation maps
NameOfSingleCellMask <- str_escape_plus("_MATISSE_Cells.tiff")
NameOfSingleCellNucleiMask <- str_escape_plus("_MATISSE_Nuclei.tiff")

# Specify marker names used for nuclear specific quantification
NuclearMarkers <- c("193Ir", "H3", "Ki-67", "FOXP3")

read_rawdata_tiffs <- function(rawfolder){
  RawFileList <- list.files(path = rawfolder, pattern = ".+(.tiff)$", full.names = TRUE)
  for (RawChannelIndex in seq_along(RawFileList)){
    if (RawChannelIndex == 1){
      RAWDATA <- list()
    }
    ChannelName <- substr(basename(RawFileList[RawChannelIndex]), 0, regexpr("(.tiff)", basename(RawFileList[RawChannelIndex]))-1)
    if (regexpr("object", ChannelName) == -1){
      #exclude segmentation map from quantification channels, read all others to list
      RAWDATA[[ChannelName]] <- readTIFF(RawFileList[RawChannelIndex])
    }
  }
  return(RAWDATA)
}

raw_to_single_cell_data <- function(RAWDATA, rawfolder, mask, ROInrs,
                                    masknuclfile, NuclearMarkers){
  masknucl <- readTIFF(masknuclfile, as.is = T)

  AllSingleCellDataFrame <- foreach(i = seq_along(ROInrs), .combine = rbind) %dopar% {
    SingleCellDataFrame <- data.frame("ROInr" = i)

    # Indexes of pixels associated with current cell
    MaskCellIndexes <- which(mask == i, arr.ind = T)
    MaskNuclIndexes <- which(masknucl == i, arr.ind = T)

    # Number of pixels per cells equals surface area
    SingleCellDataFrame[, "Cell_Area"] <- length(MaskCellIndexes)
    SingleCellDataFrame[, "Nucl_Area"] <- length(MaskNuclIndexes)

    for (ChannelIndex in seq_along(RAWDATA)){
      ChannelName <- names(RAWDATA)[ChannelIndex]
      # Single-cell pixel intensities for current channel
      RawCellData <- RAWDATA[[ChannelIndex]][MaskCellIndexes]
      # Calculate and store single-cell data to dataframe
      SingleCellDataFrame[, paste0(ChannelName, "_Mean")] <- mean(RawCellData)
      SingleCellDataFrame[, paste0(ChannelName, "_Median")] <- median(RawCellData)
      SingleCellDataFrame[, paste0(ChannelName, "_Int")] <- sum(RawCellData)

      if (is.element(ChannelName, NuclearMarkers)){
        # For channel names marked as nuclear, calculate data for nuclear pixels.
        RawNuclData <- RAWDATA[[ChannelIndex]][MaskNuclIndexes]
        SingleCellDataFrame[, paste0(ChannelName, "_Nucl_Mean")] <- mean(RawNuclData)
        SingleCellDataFrame[, paste0(ChannelName, "_Nucl_Median")] <- median(RawNuclData)
        SingleCellDataFrame[, paste0(ChannelName, "_Nucl_Int")] <- sum(RawNuclData)
      }
    }
    # Now return a df for a single-cell from the parallel loop.
    SingleCellDataFrame
  }
  return(AllSingleCellDataFrame)
}

# Find all raw data folders in the defined exportfolder
DatasetFolderList <- list.files(path = PathRawData, full.names = T)

for (RegionIndex in seq_along(DatasetFolderList)) {
  print(paste("Busy with", RegionIndex, "Of", length(DatasetFolderList)))
  # Extract information from the region foldername
  RegionName <- basename(DatasetFolderList[RegionIndex])

  # Find the segmentation map associated with the raw data
  maskfile <- paste0(Segmentationpath, RegionName, NameOfSingleCellMask)
  masknuclfile <- paste0(Segmentationpath, RegionName, NameOfSingleCellNucleiMask)

  if (RegionIndex == 1) {
    FusedDF <- list()
  }
  if (file.exists(maskfile) & file.exists(masknuclfile)) {
    # Only generate data if 1 segmentation map is found for current region
    rawfolder <- DatasetFolderList[RegionIndex]
    RAWDATA <- read_rawdata_tiffs(rawfolder)

    mask <- readTIFF(maskfile, as.is = T)
    # Initialize segmentation map. Load all ROI numbers and test if at least 10 cell identified.
    ROInrs <- sort(unique(c(mask))[unique(c(mask)) > 0])
    if (length(ROInrs) > 10) {
      print(paste("Number of cells identified:", length(ROInrs)))

      # Generate single cell data with segmentation mask and raw data
      FusedDF[[RegionName]] <- raw_to_single_cell_data(RAWDATA, rawfolder,
                                                        mask, ROInrs,
                                                        masknuclfile,
                                                        NuclearMarkers)
    }
    rm(RAWDATA)
  }
  else {
    print(paste(RegionIndex, ": No Cells found"))
  }
  if (RegionIndex == length(DatasetFolderList)) {
    # When last region is completed, concatenate and save results table
    FusedDF <- bind_rows(FusedDF, .id = "ImageNumber")
    save(FusedDF, file = outputfile)
  }
}
