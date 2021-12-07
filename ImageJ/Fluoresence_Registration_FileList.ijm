// ONLY 1 image can be used per FOV
// check if orientation of images is the same, flip / rotation
print("\\Clear");

MOPSvsSIFT = "SIFT";
Linear = false;
skipifexists = true;
overlay = true;
morphfeat = false;
keepopen = false;
setBatchMode(true);

var initial_gaussian_blur = 3;
var steps_per_scale_octave = 3;
var minimum_image_size = 100;
var maximum_image_size = 1500;
var feature_descriptor_size = 8;
var maximal_alignment_error = 10;

var deltaT = "";

//scale of IMC to IF resolution
scale = 4.348; // Z1
//scale = 3.199; // CellObserver

margin = 0.10; //alowed error margin scale of predicted transformation
align = true;

path = getDirectory("select folder");
path_export = path + "Registration/";
path_keypoints = path_export + "keypoints/";
path_overlay = path_export + "overlay/";

//matchedfile = "/data/Microscopy_SlideScan/CellObserver/MatchedIF_IMC.txt";
//exportifpath = "/data/IMC-data/DATA/Matthijs/MBAA033/matchedIF2/";
//roisavepath = exportifpath + "keypoints/";
//overlaysavepath = exportifpath + "overlay/";

//Create folders if they dont exist yet
MakeFolder(path_export);
MakeFolder(path_keypoints);
if (overlay) {
	MakeFolder(path_overlay);
}

function MakeFolder(path) { 
	if (!File.exists(path)){
		File.makeDirectory(path);
	}
}

//Make progress bar
title_progress = "[Progress]";
run("Text Window...", "name="+ title_progress +" width=35 height=5 monospaced");

//Initiate logfile
getDateAndTime(year, month, null, dayOfMonth, hour, minute, second, msec);
datetimestring = d2s(year, 0) + "-" + month + "-" + dayOfMonth + "-" + hour + "-" + minute + "-" + second;
logfilepath = path_export + datetimestring + "_alignmentlog.txt";
logfile = File.open(logfilepath);
File.close(logfile);
File.append("status,MCDFile,IFFIle,CandidateNr,MatchNr,AlignmentError,IFUI,searchTime,Scale,StdDev,Date,Time", logfilepath);

//TransformationScale
var SelectionScale = 0;
var SelectionScaleSTD = 0;

//Read FileList
file_matched_path = path + "FileList.csv";
file_matched_array_record = split(File.openAsString(file_matched_path),"\n");
number_of_files = file_matched_array_record.length;
//Array.show(file_matched_array_record);

//Search log start position for keypoint information
keypointsparamsLineNumber = 0;

for (i_match = 1; i_match < file_matched_array_record.length; i_match++) {
	print(title_progress, "\\Update:"+i_match+"/"+number_of_files+" ("+i_match/number_of_files*100+"%)\n"+getBar(i_match, number_of_files));
	
	file_matched_array_record_fields = split(file_matched_array_record[i_match], ";");
	
	path_fluor = unquoteString(file_matched_array_record_fields[0]);
	path_imc = unquoteString(file_matched_array_record_fields[1]);
	print(path_imc);
	
	name_region = unquoteString(file_matched_array_record_fields[2]);
	path_export_image = path_export + name_region + ".tiff";
	print(path_export_image);
	
	if (!File.exists(path_export_image) || !skipifexists) {
		keypoints = findaligment(path_imc, path_fluor, path_keypoints, false, align, MOPSvsSIFT);
		
		//Search log for keypoint information
		keypointsparams = findKeypointParamsLog(parseInt(keypointsparamsLineNumber));
		keypointsparamsLineNumber = substring(keypointsparams, 0, indexOf(keypointsparams, ","));
		keypointsparamsOther = substring(keypointsparams, indexOf(keypointsparams, ",")+1, lengthOf(keypointsparams));

		string = name_region + "," + keypointsparamsOther + "," + deltaT;

		if (keypoints) {
			print("FOUND matching points for images");
			//Test expected transformation is in line with image scale difference
			ScaleTest = TestEstimatedTransformationScaleRandom(File.getName(path_imc), File.getName(path_fluor), scale, margin);
			if (ScaleTest) {
				print("Transformation is within alowed range");
				getDateAndTime(year, month, null, dayOfMonth, hour, minute, second, null);
				logstring = "matched," + string + "," + SelectionScale + "," + SelectionScaleSTD + "," + year + "-" + month + "-" + dayOfMonth + "," + hour + ":" + minute + ":" + second;
				File.append(logstring, logfilepath);
				if (align) {
					ID = alignIMCtoIFunscaled(path_imc, path_fluor, scale, keepopen, Linear, path_export_image, overlay);
					if (overlay){
						overlaysavename = path_overlay + name_region + "_Overlay.jpg";
						overlayalignedIF(ID, overlaysavename);
					}
				}
			} else {
				print("Transformation is outside range");
				getDateAndTime(year, month, null, dayOfMonth, hour, minute, second, null);
				logstring = "invalid," + string + "," + SelectionScale + "," + SelectionScaleSTD + "," + year + "-" + month + "-" + dayOfMonth + "," + hour + ":" + minute + ":" + second;
				File.append(logstring, logfilepath);
				if (!keepopen) { //if no maches, and if image no longer needed, close it
					if (isOpen(File.getName(path_fluor))) {
						selectWindow(File.getName(path_fluor));
						close();
					}
				}
				if (isOpen(File.getName(path_imc))) { //if no matches, close mcd image
					selectWindow(File.getName(path_imc));
					close();
				}
			}
		} else {
			print("No keypoints found");
			getDateAndTime(year, month, null, dayOfMonth, hour, minute, second, null);
			logstring = "failed," + string + ",NULL,NULL," + year + "-" + month + "-" + dayOfMonth + "," + hour + ":" + minute + ":" + second;
			File.append(logstring, logfilepath);
			if (!keepopen) { //if no maches, and if image no longer needed, close it
				if (isOpen(File.getName(path_fluor))) {
					selectWindow(File.getName(path_fluor));
					close();
				}
			}
			if (isOpen(File.getName(path_imc))) { //if no matches, close mcd image
				selectWindow(File.getName(path_imc));
				close();
			}
		}
	} else {
		print("Output exists");
	}
	PurgeGarbage();
}
print(title_progress, "\\Close");
print("ALL alignments DONE!");

if (morphfeat){
	print("Will now generate Morph Feat");
	runMacro("/IF macro/IF-DAPI-FeaturGen.ijm", exportifpath);
	print("MorphFeat complete");
}

showMessage("done");

function PurgeGarbage(){
	run("Collect Garbage");
	call("java.lang.System.gc");
	if (isOpen("Exception")){
		selectWindow("Exception");
		run("Close");
	}
}

function unquoteString(string){
	return replace(string, "\"", "");
}

function TestEstimatedTransformationScaleRandom(imcimage, ifimage, scale, margin){
	selectWindow(imcimage);
	getSelectionCoordinates(Sxpoints, Sypoints);
	selectWindow(ifimage);
	getSelectionCoordinates(Txpoints, Typoints);
	
	random("seed", 14);
	length = Sxpoints.length-1;
	ScaleArray = newArray();
	
	//for random sets of points measure distance and calculate scale, 1/3 of all points
	if (length < 20) {
		n = 5;
	} else {
		n = round(Sxpoints.length/3);
	}
	
	for (i = 0; i < n; i++) {
		I1 = round((length)*random());
		I2 = round((length)*random());
		
		SourceDist = CalcDistance(Sxpoints, Sypoints, I1, I2);
		TargetDist = CalcDistance(Txpoints, Typoints, I1, I2);

		if (SourceDist > 0 && TargetDist > 0) {
			ScaleArray = Array.concat(ScaleArray, TargetDist/SourceDist);
		}
	}
	Array.show(ScaleArray);
	Array.getStatistics(ScaleArray, min, max, mean, stdDev);
	LimitScaleLower = scale*(1-margin);
	LimitScaleUpper = scale*(1+margin);
	
	//print("MEAN: " + mean + " above: " + LimitScaleLower + " below: " + LimitScaleUpper);
	print("MEAN: " + getBarMinMax(LimitScaleLower, LimitScaleUpper, mean) + " " + mean);
	print("stdDev: " + stdDev + " below: " + 0.3);
	
	SelectionScale = mean;
	SelectionScaleSTD = stdDev;
	
	if (mean >= LimitScaleLower && mean <= LimitScaleUpper && stdDev < 0.3) {
		return true;
	} else {
		return false;
	}
}

function CalcDistance(Xpoints, Ypoints, I1, I2) {
	dx = Xpoints[I1] - Xpoints[I2];
	dy = Ypoints[I1] - Ypoints[I2];
	dist = sqrt(pow(dx, 2) + pow(dy, 2));
	return dist;
}

function getBarMinMax(min, max, actual) {
	n = 50; // resolution
	percentage = 1-(max - actual)/(max - min);
	index = round(n*(percentage));
	//if (index < 1) index = 1;
	if (index > n-1) index = n-1;
	string = "[";
	separator = "<|>";
	for (i = 0; i < n; i++) {
		if (i == index) {
			string = string + separator;
		} else {
			string = string + " ";
		}
	}
	string = string + "]";
	
	if (actual < min) string = "[          too LOW          ]";
	if (actual > max) string = "[          too HIGH         ]";
	
	return string;
}

function getBar(p1, p2) {
	n = 20;
	bar1 = "--------------------";
	bar2 = "********************";
	index = round(n*(p1/p2));
	if (index<1) index = 1;
	if (index>n-1) index = n-1;
	return substring(bar2, 0, index) + substring(bar1, index+1, n);
}

function overlayalignedIF(id, overlaysavename) {
	//prep IR193 image
	selectWindow("scaled");
	resetMinAndMax;
	run("Enhance Contrast", "saturated=0.35");
	getMinAndMax(null, max);
	setMinAndMax(0, max);
	
	//prepare IF image
	selectImage(id);
	rename("iffile");
	getDimensions(width, height, null, null, null);
	//run("16-bit");
	resetMinAndMax;
	run("Enhance Contrast", "saturated=0.35");
	
	//make keypoint image
	newImage("Points", "8-bit black", width, height, 1);
	roiManager("select", 2); //select scaled keypoint data
	setForegroundColor(255, 255, 255);
	run("Draw", "slice"); run("Dilate"); run("Dilate");
	run("16-bit");
	
	//make composite
	run("Merge Channels...", "c1=scaled c3=iffile c4=Points create");
	save(overlaysavename);
	close();
}

function findKeypointParamsLog(searchUntil){
	logcontent = getInfo("log");
	if (logcontent != ""){
		loglines = split(logcontent, "\n");
		PotentialCandidates = "";
		CorrespondingFeatures = "";
		Displacement = "";
		//if no info is found, only linenumber will be returned, but searchUntil is not modified
		linenumber = d2s(searchUntil, 0);
		for (i = loglines.length-1; i >= searchUntil; i--){
			if (matches(loglines[i], "^[0-9]+( potentially corresponding features identified.)$")){
				PotentialCandidates = substring(loglines[i], 0, indexOf(loglines[i], " potentially"));
				//stop searching
				i = searchUntil;
			}
			if (matches(loglines[i], "^(No correspondences found.)$")){
				CorrespondingFeatures = "0";
				Displacement = "";
				//store last line index of search, dont go further back next search
				linenumber = d2s(i+1,0);
			}
			if (matches(loglines[i], "^[0-9]+( corresponding features with a maximal displacement of )[0-9]+.?[0-9]+(px identified.)$")){
				CorrespondingFeatures = substring(loglines[i], 0, indexOf(loglines[i], " corresponding"));
				Displacement = substring(loglines[i], indexOf(loglines[i], " of ")+4, indexOf(loglines[i], "px "));
				//store last line index of search, dont go further back next search
				linenumber = d2s(i+1,0);
			}
			if (matches(loglines[i], "^(Processing )(MOPS|SIFT)( ...)$")){
				//stop searching
				i = searchUntil;
			}
		}
		string = linenumber + "," + PotentialCandidates + "," + CorrespondingFeatures + "," + Displacement;
		return string;
	}
}

function alignIMCtoIFunscaled(imcfile, iffile, scale, keepopen, Linear, savename, overlay){
	// blow up imc image to match fluor resolution
	imcfile = File.getName(imcfile);
	selectWindow(imcfile);
	getDimensions(width, height, null, null, null);
	run("Scale...", "x=["+scale+"] y=["+scale+"] width=["+width*scale+"] height=["+height*scale+"] interpolation=None average create title=scaled");
	// close unscaled image
	selectWindow(imcfile);
	close();
	
	//scale keypoints to new image size
	selectWindow("scaled");
	roiManager("select", 0);
	run("Scale... ", "x=["+scale+"] y=["+scale+"]"); 
	roiManager("add");
	
	iffile = File.getName(iffile);
	if (Linear){
		run("Landmark Correspondences", "source_image=["+iffile+"] template_image=scaled transformation_method=[Least Squares] alpha=1 mesh_resolution=32 transformation_class=Similarity interpolate");
	}
	if (!Linear){
		run("Landmark Correspondences", "source_image=["+iffile+"] template_image=scaled transformation_method=[Moving Least Squares (non-linear)] alpha=1 mesh_resolution=32 transformation_class=Similarity interpolate");
	}
	selectWindow("Transformed" + iffile);
	save(savename);
	ID = getImageID();
	if (!keepopen){
 //close template IF image if not further alignments to be done
		selectWindow(iffile);
		close();
	}
	
if (!overlay){
		//clear roi manager after success full alignment
		roiManager("reset");
		selectWindow("scaled");
		close();
		//close transformed IF image if no overlay requested
		selectImage(ID);
		close();
	}
	return ID;
}


function findaligment(source, target, roisavepath, keepopen, align, MOPSvsSIFT){
	if (!isOpen(File.getName(source))){
		open(source);
		resetMinAndMax;
		run("Enhance Contrast", "saturated=0.35");
		getMinAndMax(null, max);
		setMinAndMax(0, max);
	}
	if (!isOpen(File.getName(target))){
		open(target);
		resetMinAndMax;
		run("Enhance Contrast", "saturated=0.35");
		//run("Rotate 90 Degrees Right");
		//run("Flip Horizontally");
	}
	source = File.getName(source);
	target = File.getName(target);

	//remove existing selections before making new
	selectWindow(source);
	run("Select None");
	selectWindow(target);
	run("Select None");

	//clear roimanager
	roiManager("reset");
	
//Find alignment keypoints for IF towards IMC
	startTime = getTime();
	if (MOPSvsSIFT == "SIFT"){
		run("Extract SIFT Correspondences", "source_image=["+name_target+"] target_image=["+name_source+"] initial_gaussian_blur=["+initial_gaussian_blur+"] steps_per_scale_octave=["+steps_per_scale_octave+"] minimum_image_size=["+minimum_image_size+"] maximum_image_size=["+maximum_image_size+"] feature_descriptor_size=["+feature_descriptor_size+"] feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 filter maximal_alignment_error=["+maximal_alignment_error+"] minimal_inlier_ratio=0.05 minimal_number_of_inliers=7 expected_transformation=Affine");
	}
	if (MOPSvsSIFT == "MOPS"){
		run("Extract MOPS Correspondences", "source_image=["+name_target+"] target_image=["+name_source+"] initial_gaussian_blur=["+initial_gaussian_blur+"] steps_per_scale_octave=["+steps_per_scale_octave+"] minimum_image_size=["+minimum_image_size+"] maximum_image_size=["+maximum_image_size+"] feature_descriptor_size=["+feature_descriptor_size+"] closest/next_closest_ratio=0.92 maximal_alignment_error=["+maximal_alignment_error+"] inlier_ratio=0.05 expected_transformation=Affine");
	}
	endTime = getTime();
	deltaT = d2s((endTime-startTime)/1000, 0) + "s";
	selectWindow(source);
	if (selectionType()!=-1){
		roiManager("add");
		roiManager("select", 0);
		roiManager("rename", "source-"+source);
	}
	selectWindow(target);
	if (selectionType()!=-1){
		selection = true;
		roiManager("add");
		roiManager("select", 1);
		roiManager("rename", "target-"+target);
		roiManager("save", roisavepath+"Source-"+source+"Target-"+target+".zip");
		if (!align){
			roiManager("reset");
		}
	} else{
		selection = false;
	}
	if (!align){
		if (!keepopen){ //keep IF image open for other mcd files
			selectWindow(target);
			close();
		}
		selectWindow(source);
		close();
	}
	return selection;
}

function ArrayUnique(array) {
	array 	= Array.sort(array);
	array 	= Array.concat(array, 999999);
	uniqueA = newArray();
	i = 0;
   	while (i<(array.length)-1) {
		if (array[i] == array[(i)+1]) {
			//print("found: "+array[i]);
		} else {
			uniqueA = Array.concat(uniqueA, array[i]);
		}
   		i++;
   	}
	return uniqueA;
}

