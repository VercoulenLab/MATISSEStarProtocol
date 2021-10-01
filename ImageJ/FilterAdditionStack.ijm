/*
This ImageJ script is used to add filtered images of a single image at a time to a stack.
All images are arranged as channels in the stack.

Depends on the following plugins:
FeatureJ
MorphoLibJ

*/

path = getDirectory("Choose a Directory");
exportpath = path + "Morph-Feat/";

if (!File.exists(exportpath)){
	File.makeDirectory(exportpath);
}

// Filter instructions as concatenated string
MorphOperations = "Opening-1,Opening-2,Opening-3,Opening-5,Internal Gradient-1,Internal Gradient-3,Internal Gradient-5,White Top Hat-8,White Top Hat-10,White Top Hat-15,White Top Hat-20";
MorphOperations = split(MorphOperations, ",");
FeatureOperations = "Edges-1,Edges-2,Laplacian-0.7,Laplacian-1,Laplacian-1.6,Laplacian-2,Laplacian-3,Hessian-smallest-3,Hessian-smallest-5,Hessian-largest-1,Hessian-largest-2,Structure-largest-1-2,Structure-largest-2-2,Gaussian-0.7,Gaussian-1.6,Gaussian-2,Gaussian-3.5";
FeatureOperations = split(FeatureOperations, ",");

setBatchMode(true);

filelist = getFileList(path);
length = filelist.length;
for (i = 0; i < length; i++){
	if ((endsWith(filelist[i], ".tiff") || endsWith(filelist[i], ".tif")) && !endsWith(filelist[i], "-Morph-Feat.tif")){
		// Only process tiff files in folder
		if (!File.exists(exportpath + substring(filelist[i], 0, indexOf(filelist[i], ".tif")) + "-Morph-Feat.tiff")){
			// If file is not yet created
			open(path + filelist[i]);
			rename("input");
			run("Grays");
			id = getImageID();
			// Create stack for all morphology filters
			morphtitle = generateMorphStack("input", id, MorphOperations);
			// Create stack for all normal filters
			feattitle = generateFeatureStack("input", id, FeatureOperations);
			// Concatenate original image and filter stacks
			run("Concatenate...", "  title=output image1=input image2=["+morphtitle+"] image3=["+feattitle+"]");
			// Set dimensions of stack to all channels
			size = MorphOperations.length + FeatureOperations.length + 1;
			run("Properties...", "channels="+size+" slices=1 frames=1 unit=pixel pixel_width=1.0000 pixel_height=1.0000 voxel_depth=1.0000");

			// Set label for each image of the stack
			operations = Array.concat(filelist[i], MorphOperations, FeatureOperations);
			for (j = 0; j < size; j++) {
				Stack.setChannel(j+1);
				setMetadata("Label", operations[j]);
			}
			// Save and close image
			save(exportpath + substring(filelist[i], 0, indexOf(filelist[i], ".tif")) + "-Morph-Feat.tiff");
			close();
			print("Done with: "+i+1+" of "+length);
		}
		print(i + " " + filelist[i]);
	}
}
print("All files done");

function generateMorphStack(title, id, MorphOperations){
	operations = MorphOperations;
	for (i = 0; i < operations.length; i++){
		selectImage(id);
		settings = split(operations[i], "-");
		run("Morphological Filters", "operation=["+settings[0]+"] element=Disk radius=["+settings[1]+"]");
		selectWindow("input" + "-" + settings[0]);
		rename(operations[i]);
		if (i == 0){
			ConcatenateString = "  title=["+"input" + "-Morph"+"] ";
		}
		ConcatenateString = ConcatenateString + "image" + i + 1 + "=["+operations[i]+"] ";
	}
	run("Concatenate...", "["+ConcatenateString+"]");
	return "input" + "-Morph";
}

function generateFeatureStack(title, id, FeatureOperations){
	operations = FeatureOperations;
	for (i = 0; i < operations.length; i++){
		selectImage(id);
		settings = split(operations[i], "-");
		if (settings[0] == "Edges"){
			run("FeatureJ Edges", "compute smoothing="+settings[1]+" lower=[] higher=[]");
			setMinAndMax(0, 6000);
			run("16-bit");
		}
		if (settings[0] == "Laplacian"){
			run("FeatureJ Laplacian", "compute smoothing="+settings[1]+"");
			setMinAndMax(-8000, 8000);
			run("16-bit");
		}
		if (settings[0] == "Hessian"){
			run("FeatureJ Hessian", ""+settings[1]+" absolute smoothing="+settings[2]+"");
			if (settings[1] == "smallest"){
				setMinAndMax(0, 500);
			}
			if (settings[1] == "largest"){
				setMinAndMax(0, 3000);
			}
			run("16-bit");
		}
		if (settings[0] == "Structure"){
			run("FeatureJ Structure", ""+settings[1]+" smoothing="+settings[2]+" integration="+settings[3]+"");
			setMinAndMax(0, 15000000);
			run("16-bit");
		}
		if (settings[0] == "Gaussian"){
			run("Duplicate...", " ");
			run("Gaussian Blur...", "sigma=["+settings[1]+"]");
		}
		rename(operations[i]);
		if (i == 0){
			ConcatenateString = "  title=["+"input" + "-Feat"+"] ";
		}
		ConcatenateString = ConcatenateString + "image" + i + 1 + "=["+operations[i]+"] ";
	}
	run("Concatenate...", "["+ConcatenateString+"]");
	return "input" + "-Feat";
}
