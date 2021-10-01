/*
This macro is used to generate training data for machine learning (with Ilastik).
Used are asked to annotate representative nuclei in a set of images.
It is crucial that the entire nucleus is annotated.

First open a single image in ImageJ, then run the macro.
Press B to store the generated annotation.
Press space to stop annotations

Previously generated annotation are imported when executing the macro again on the same image.

First open a single image, then run the macro.
*/

imagepath = getDirectory("image");
title = getTitle();
roisavename = substring(title, 0, indexOf(title, ".tif")) + ".zip";

// Create directories for storing files
annotationpath = imagepath + "Annotations/";
overlaypath = annotationpath + "Overlay/";
maskpath = annotationpath + "Mask/";
if (!File.exists(annotationpath)){
	File.makeDirectory(annotationpath);
}
if (!File.exists(overlaypath)){
	File.makeDirectory(overlaypath);
}
if (!File.exists(maskpath)){
	File.makeDirectory(maskpath);
}

// Import generated annotations
if (File.exists(annotationpath + roisavename)){
	roiManager("reset");
	roiManager("open", annotationpath + roisavename);
	run("From ROI Manager");
	roiManager("reset");
}

// The annotation dialog
options = newArray("Nuclei", "Background", "modify", "save", "reset", "unsaved stop");
run("Grays");
continuecycle = true;
while (continuecycle){
	Dialog.create("What to do?");
	Dialog.addRadioButtonGroup("Option", options, 4, 1, "Nuclei");
	Dialog.show();
	Decision = Dialog.getRadioButton();

	if (Decision == "Nuclei"){
		continuecycle = true;
		setTool("brush");
		call("ij.gui.Toolbar.setBrushSize", 5);
		run("Colors...", "selection=red");
		waitForUser("Draw all CELL annotations, add with B, press OK to continue");
	}
	if (Decision == "Background"){
		continuecycle = true;
		setTool("brush");
		call("ij.gui.Toolbar.setBrushSize", 20);
		run("Colors...", "selection=green");
		waitForUser("Draw all BACKGROUND annotations, add with B, press OK to continue");
	}
	if (Decision == "modify"){
		// Imports all generated annotation to the ROI Manager. User is alowed to delete/update.
		continuecycle = true;
		run("To ROI Manager");
		run("Remove Overlay");
		waitForUser("Edit ROIs in ROI manager, press OK to continue");
		run("From ROI Manager");
		roiManager("reset");
	}
	if (Decision == "save"){
		// Processes all generated annotations and saves to files. Stops the dialog cycle.
		setBatchMode(true);
		continuecycle = false;
		run("To ROI Manager");
		roiManager("save", annotationpath + roisavename);
		RoiToMask(title, maskpath);
		run("From ROI Manager");
		roiManager("reset");
		run("Select None");
		saveAs("PNG", overlaypath + title);
		close();
		if (isOpen("ROI Manager")){
			selectWindow("ROI Manager");
			run("Close");
		}
		setTool("hand");
		run("Colors...", "selection=yellow");
		setBatchMode(false);
		showMessage("Saving is complete");
	}
	if (Decision == "reset"){
		// Start from scratch with annotations
		continuecycle = true;
		run("Remove Overlay");
		roiManager("reset");
	}
	if (Decision == "unsaved stop"){
		continuecycle = false;
		run("Remove Overlay");
		roiManager("reset");
		close();
	}
}

function RoiToMask(title, maskpath) {
	// Save ROIs to intepretable mask for machine learning
	selectWindow(title);
	getDimensions(width, height, null, null, null);
	newImage("MASK", "8-bit black", width, height, 1);
	n = roiManager("count");
	for (i = 0; i < n; i++) {
		roiManager("select", i);
		color = Roi.getStrokeColor;
		if (color == "yellow" || color == "red"){
			// Nuclei - fill
			c = 2;
			setForegroundColor(c, c, c);
			roiManager("select", i);
			roiManager("fill");
			// Nuclei - edge
			c = 3;
			setForegroundColor(c, c, c);
			roiManager("select", i);
			roiManager("draw");
			roiManager("select", i);
			Roi.setStrokeColor("red");
			roiManager("update");
		}
		if (color == "green"){
			// Background - fill
			roiManager("Set Fill Color", "#3000ff00");
			c = 1;
			setForegroundColor(c, c, c);
			roiManager("select", i);
			roiManager("fill");
			roiManager("select", i);
			roiManager("draw");
		}
	}
	saveAs("TIFF", maskpath + title);
	close();
}
