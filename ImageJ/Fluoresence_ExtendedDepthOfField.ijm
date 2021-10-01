print("\\Clear");
if (getArgument()!="") {
	argument=getArgument();
	print(argument);
	arguments=split(argument,",");
	inputfolder=arguments[0];
	outfolder=arguments[1];
}
else{
	print("No argument given");
	inputfolder = getDirectory("Choose a Directory");
}

filelist = getFileList(inputfolder);
npar = 11;
time_wait_max = 5 * 60 * 1000; // 5 min

setBatchMode(true);
getDateAndTime(year, month, null, dayOfMonth, hour, minute, null, null);

fullFolderList = newArray();
for (i = 0; i < filelist.length; i++){
	if (endsWith(filelist[i], "/")) {
		subfolder = filelist[i];
		subfolder_filelist = getFileList(inputfolder + subfolder);
		
		for (j = 0; j < subfolder_filelist.length; j++) {
			if (endsWith(subfolder_filelist[j], "_stacks/")) {
				path_stacks = inputfolder + subfolder + subfolder_filelist[j];
				path_stacks_filelist = getFileList(path_stacks);
				print(path_stacks_filelist.length);

				outfolder = path_stacks + "EDF/";
				if (!File.exists(outfolder)) {
					File.makeDirectory(outfolder);
				}

				for (k = 0; k < path_stacks_filelist.length; k++) {
					if (endsWith(path_stacks_filelist[k], ".tiff") || endsWith(path_stacks_filelist[k], ".tif")) {
						expectedOutputPath = outfolder + substring(path_stacks_filelist[k], 0, indexOf(path_stacks_filelist[k], ".tif")) + "_EDF.tiff";
						if (!File.exists(expectedOutputPath)) {
							fullFolderList = Array.concat(fullFolderList, path_stacks + path_stacks_filelist[k]);
						}
					}
				}
			}
		}
	}
}

//Array.show(fullFolderList);
print("Nr images to process: " + fullFolderList.length);
//fullFolderListsubset = Array.trim(fullFolderList, 3);

MultiStackToEDF1C(fullFolderList, npar, inputfolder, time_wait_max);
showMessage("Processing completed!");

function MultiStackToEDF1C(FileList, npar, inputfolder, time_wait_max) {
	for (i = 0; i < FileList.length; i=i) {
		getDateAndTime(year, month, null, dayOfMonth, hour, minute, second, msec);
		print(year+"-"+month+"-"+dayOfMonth+"  "+hour+":"+minute+":"+second);

		// Test number of files remaining in filelist
		if (i + npar <= FileList.length) {
			maxi = i + npar;
		} else {
			maxi = FileList.length;
		}
		
		// Loop with increment npar
		ImagesToRetrieve = newArray();
		
		// Run EDF
		for (i = i; i < maxi; i++) {
			print(i + " " + FileList[i]);
			open(FileList[i]);
			title = d2s(i,0); //File.getName(FileList[i]);
			rename(title);
			
			ImagesToRetrieve = Array.concat(ImagesToRetrieve, title + "_EDF");
			run("EDF Easy ", "quality=4 topology=4 show-topology='off' show-view='off'");
			wait(100);
		}
		
		// Wait for all EDF windows to open, but restrict maximum wait time
		time_wait_start = getTime();
		for (x = 0; x < ImagesToRetrieve.length; x++) {
			while (!isOpen(ImagesToRetrieve[x]) || getTime() >= time_wait_start + time_wait_max){
				wait(100);
			}
		}
		wait(250);

		// Close all input windows
		for (x = 0; x < ImagesToRetrieve.length; x++) {
			ImageTitle = replace(ImagesToRetrieve[x], "_EDF", "");
			if (isOpen(ImageTitle)) {
				selectImage(ImageTitle);
				close();
			}
		}

		// Save images & close
		for (x = 0; x < ImagesToRetrieve.length; x++) {
			C1Title = ImagesToRetrieve[x];
			
			ImageTitle = replace(C1Title, "_EDF", "");
			path_source = FileList[parseInt(ImageTitle)];
			outTitle = File.getName(path_source);
			path_output = File.getParent(path_source) + "/EDF/";
			
			savename = path_output + substring(outTitle, 0, indexOf(outTitle, ".tif")) + "_EDF.tiff";
			print(savename);

			if (isOpen(C1Title)) {
				selectImage(C1Title);
				setMinAndMax(0, 65535);
				run("16-bit");
				save(savename);
				close();
			} else {
				print("ERROR  " + C1Title);
			}
			wait(50);
		}
		PurgeGarbage();
	}
}

/*
function StackToEDF2C(file, exportpath){
		print(file);
		title = File.getName(file);
		open(file);
				getDateAndTime(year, month, null, dayOfMonth, hour, minute, second, msec);
				print("y"+year+"_m"+month+"_d"+dayOfMonth+"_h"+hour+"_m"+minute+"_s"+second);
				selectWindow(title);
				run("Split Channels");
				oldtime=getTime();
				selectWindow("C1-"+title);
				rename("C1");
				run("EDF Easy ", "quality=4 topology=4 show-topology='off' show-view='off'");
				selectWindow("C2-"+title);
				rename("C2");
				run("EDF Easy ", "quality=4 topology=4 show-topology='off' show-view='off'");

				newtime=getTime();
				while ((!isOpen("C1_EDF")&&!isOpen("C2_EDF"))||(((newtime-oldtime)/1000)>120)){ //wait for 2 min max for output window to open
					newtime=getTime();
					wait(50);
				}
				selectWindow("C1"); close();
				selectWindow("C2"); close();
				
				if (isOpen("C1_EDF")){
					selectWindow("C1_EDF");
					setMinAndMax(0, 65535);
					run("16-bit");
					C1id = true;
				} else {
					C1id = false;
				}
				if (isOpen("C2_EDF")){
					selectWindow("C2_EDF");
					setMinAndMax(0, 65535);
					run("16-bit");
					C2id = true;
				} else {
					C2id = false;
				}
				
				if (C1id && C2id){
					//if (isOpen("C1_EDF") && isOpen("C2_EDF")){ //only merge if both files are made
					run("Merge Channels...","c1=C1_EDF c2=C2_EDF create");
					savename = exportpath + substring(title, 0, indexOf(title, ".tif")) + "_EDF.tiff";
					print(savename);
					save(savename); //include data or foldername in savepath
					close();
				} else { //write to logfile
					printtolog(file +"\t generation fail", exportpath);
					if(isOpen("C1_EDF")){
						selectWindow("C1_EDF");
						close();
					}
					if(isOpen("C2_EDF")){
						selectWindow("C2_EDF");
						close();
					}
				}
			} else{
				print("EDF file exists");
			}
		}
	}
}
*/

function PurgeGarbage(){
	run("Collect Garbage");
	call("java.lang.System.gc");
	if (isOpen("Exception")){
		selectWindow("Exception");
		run("Close");
	}
}

function printtolog(file, exportpath){
	getDateAndTime(year, month, null, dayOfMonth, hour, minute, null, null);
	logname = exportpath+"log_y"+year+"m"+month+"d"+dayOfMonth+"h"+hour+"m"+minute+".txt";
	if (!File.exists(logname)){
		logfile = File.open(logname);
		File.close(logfile);
	}
	File.append(file, logname);
}

function StackToEDF1C(title){
	oldtime=getTime();
	run("EDF Easy ", "quality=4 topology=4 show-topology='off' show-view='off'");
	newtime=getTime();
	while (!isOpen(title+"_EDF")||(((newtime-oldtime)/1000)>120)){ //wait for 2 min max for output window to open
		newtime=getTime();
		wait(50);
	}
	selectWindow(title);
	close();
	if (isOpen(title+"_EDF")){
		selectWindow(title+"_EDF");
		setMinAndMax(0, 65535);
		run("16-bit");
		return title+"_EDF";
	}else{
		print("No output");
		return "";
	}
}
