channels = newArray(1,2,3,4,5,6,7,8,9,10,11,12,14,16,17,18);
maxInt = newArray(300,290,20,9,30,28,12,10,13,15,90,60,520,40,13,35);

directory = getDirectory("Select folder with stacked tiffs and click open");
setBatchMode(true);


// Create a directory
  MyDir = getDirectory("Select folder of parental folder")+"MachineLearning";
  File.makeDirectory(MyDir);
  if (!File.exists(MyDir))
      exit("Unable to create directory");
  print("");
  print(MyDir);


filelist = getFileList(directory);
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tiff")) {
        open(directory + "/" + filelist[i]);
        title_short = substring(filelist[i], 0, indexOf(filelist[i], ".tiff"));
        id_source = getImageID();

        id_output = makeSubstackScaled(id_source, channels, maxInt);
		
        selectImage(id_output);
        path_save = File.getParent(directory) + "/MachineLearning/" + title_short + ".tiff";
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
        
        