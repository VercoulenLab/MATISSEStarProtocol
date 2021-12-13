
channel = 3;
channel_name = "Ir193";
maxI = 200;

directory = getDirectory("Select folder with tiff stacks");
setBatchMode(true);

// Create a directory
  MyDir = getDirectory("Select folder of parental folder")+"Ir193";
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