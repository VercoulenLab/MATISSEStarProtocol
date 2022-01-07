print("\\Clear");
run("Select None");
roiManager("Reset");

numberofROIs = 2;

//scale of IMC to IF resolution
scale = 4.348; // Z1
//scale = 3.199 // CellObserver

run("Set Scale...", "distance=["+scale+"] known=1 unit=micron");

image_Height = getHeight();
image_Width = getWidth();
image_id = getImageID();
image_path = getDirectory("image");
image_title = getTitle();

image_crop_path = image_path + "subset/";
if (!File.exists(image_crop_path)){
	File.makeDirectory(image_crop_path);
}

Dialog.create("Selection size");
Dialog.addNumber("Size:", 158);
Dialog.show();

boxsize = Dialog.getNumber();
boxsize_scaled = boxsize * scale;

satisfied = false;
while (!satisfied) {
	retries = 0;
	for (i = 0; i < numberofROIs; i++){
		Xb = random() * (image_Width - boxsize_scaled);
		Yb = random() * (image_Height - boxsize_scaled);

		toScaled(Xb, Yb);
		Xb_round = round(Xb);
		Yb_round = round(Yb);
		toUnscaled(Xb_round, Yb_round);
		
		makeRectangle(Xb_round, Yb_round, boxsize_scaled, boxsize_scaled);
		roiManager("Add");
		
		// check if similar ROI not already exists, test for overlap
		if (checkOverlap()){
			// select last added roi and delete
			roiManager("select", roiManager("count")-1);
			roiManager("delete");
			retries++;
			if (retries < 50){
				i--;
				} else {
				i = numberofROIs;
				print("Too many retries, unable to find empty spot for new ROI");
			}
		}
	}
	print("COUNT " + roiManager("count"));
	print("RETRIES " + retries);

	roiManager("Show All");
	roiManager("Show All with labels");

	// create crops
	Dialog.create("Satisfied?");
	Dialog.addCheckbox("Satisfied", true);
	Dialog.show();

	satisfied = Dialog.getCheckbox();
	if (satisfied) {
		// exit loop
		break;
	} else {
		run("Select None");
		roiManager("Reset");
	}
}

// store roi coordinates & crops
path_roi_config = image_path + "SubsetROICoords.txt";
if (!File.exists(path_roi_config)){
	File.open(path_roi_config);
	string = "title,x,y,size,i";
	File.append(string, path_roi_config);
}
roi_config = File.openAsRawString(path_roi_config);
roi_config = split(roi_config, "\n");
roi_config_length = lengthOf(roi_config) - 1;

n_ROI =  roiManager("count");
for (i = 0; i < n_ROI; i++){
	selectImage(image_id);
	roiManager("select", i);
	getSelectionBounds(x, y, width, height);
	toScaled(x, y);
	n = roi_config_length + i;
	string = image_title + "," + d2s(x, 2) + "," + d2s(y, 2) + "," + d2s(boxsize, 0) + "," + d2s(n, 0);
	File.append(string, path_roi_config);

	run("Duplicate...", "title=["+n+"]");
	saveAs("tiff", image_crop_path + n + ".tiff");
	close();
}
close();


function checkOverlap() {
	n_ROI = roiManager("count");
	n_intersect = 0;
	intersect = false;
	
	for (i = 0; i < n_ROI-1; i++){
		//test only non-self overlaps
		roiManager("select", newArray(i, n_ROI-1));
		//print("TEST " + i + " " + n_ROI-1);
		roiManager("AND");
   	   	if (selectionType() > -1){
			n_intersect++;
		}
		roiManager("deselect");
		run("Select None");
	}
	if (n_intersect > 0){
		intersect = true;
	}
	return intersect;
}
