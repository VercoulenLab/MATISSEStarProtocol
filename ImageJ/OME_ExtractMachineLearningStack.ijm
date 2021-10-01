channels = newArray(4,5,6,8,9,14,18,20,23,27,30,33,38);
maxInt = newArray(80,40,45,45,45,40,30,150,70,80,35,70,180);

directory = getDirectory("Select folder with ome tiff");
setBatchMode(true);

directory_output = File.getParent(directory) + "/MachineLearning/";
if (!File.exists(directory_output)){
	File.makeDirectory(directory_output);
}

filelist = getFileList(directory);
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".ome.tiff")) {
        open(directory + "/" + filelist[i]);
        title_short = substring(filelist[i], 0, indexOf(filelist[i], ".ome.tiff"));
        id_source = getImageID();

        id_output = makeSubstackScaled(id_source, channels, maxInt);

        selectImage(id_output);
        path_save = directory_output + title_short + ".tiff";
        saveAs("tiff", path_save);
        close();

        selectImage(id_source);
        close();
    }
}
showMessage("done");

function makeSubstackScaled(id, channels, maxInt) {
	contat_string = "  title=stack ";
	for (i = 0; i < channels.length; i++) {
		selectImage(id);
		Stack.setSlice(channels[i]);
		run("Duplicate...", "title=["+i+1+"]");
		setMinAndMax(0, maxInt[i]);
		run("16-bit");
		contat_string = contat_string + "image" + d2s(i + 1, 0) + "=" + d2s(i + 1, 0) + " ";
	}
	run("Concatenate...", contat_string);
	Stack.setDimensions(channels.length, 1, 1);
	return getImageID();
}