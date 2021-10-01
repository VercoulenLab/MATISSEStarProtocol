
channel = 28;
channel_name = "Ir193";
maxI = 30;

directory = getDirectory("Select folder with ome tiff");
setBatchMode(true);

filelist = getFileList(directory);
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".ome.tiff")) { 
        open(directory + "/" + filelist[i]);
        title_short = substring(filelist[i], 0, indexOf(filelist[i], ".ome.tiff"));
        id_source = getImageID();
        
        Stack.setSlice(channel);
        run("Duplicate...", " ");
        id_channel = getImageID();
        setMinAndMax(0, maxI);
        run("16-bit");
        
        path_save = File.getParent(directory) + "/Ir193/" + title_short + ".tiff";
        saveAs("tiff", path_save);
        close();

        selectImage(id_source);
        close();
    }
}
showMessage("done");