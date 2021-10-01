// open stacks
// apply list-based crop

print("\\Clear");
run("Select None");
roiManager("Reset");

path_imc = getDirectory("select ML folder from IMC data");
path_roi_config = File.openDialog("Choose SubsetROICoords.txt file");

image_crop_path = path_imc + "subset/";
if (!File.exists(image_crop_path)){
	File.makeDirectory(image_crop_path);
}

roi_config = File.openAsRawString(path_roi_config);
roi_config = split(roi_config, "\n");

for (i = 1; i < roi_config.length; i++) {
	roi_config_fields = split(roi_config[i], ",");
	title_image = roi_config_fields[0];
	box_x = roi_config_fields[1];
	box_y = roi_config_fields[2];
	box_size = roi_config_fields[3];
	image_i = roi_config_fields[4];

	path_image = path_imc + title_image;

	if (File.exists(path_image)) {
		open(path_image);
		getDimensions(null, null, channels, null, null);
		
		id = getImageID();
		makeRectangle(box_x, box_y, box_size, box_size);
		
		if (channels > 1) {
			run("Duplicate...", "title=["+image_i+"] duplicate");
		} else {
			run("Duplicate...", "title=["+image_i+"]");
		}
		
		saveAs("tiff", image_crop_path + image_i + ".tiff");
		close();
		
		// close input image
		selectImage(id);
		close();
	}
}
print("done");