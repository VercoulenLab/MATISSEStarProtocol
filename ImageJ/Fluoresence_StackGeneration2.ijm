//for call by other macro
if (getArgument()!="") {
	directory = getArgument();
} else {
	print("\\Clear");
	directory = getDirectory("Choose a Directory");
}

//to remove separate tif and only keep stacks
delete = true;
setBatchMode(true);

//base name of czi file and all daughter tiffs
prefix = File.getName(directory);
exportpath = directory + "/" + prefix + "_stacks" + "/";
if (!File.exists(exportpath)) {
	File.makeDirectory(exportpath);
}

filelist = getFileList(directory);

// arrays containing position info for all images
Marray = newArray();
Sarray = newArray();
Zarray = newArray();
Carray = newArray();
Iarray = newArray();

// ! all tile-regions in 1 czi file always have same number of dimensions
set_format = false;
for (i = 0; i < lengthOf(filelist); i++) {
	if (endsWith(filelist[i],".tif")){
		metastring = substring(filelist[i],lengthOf(prefix),indexOf(filelist[i],"_ORG.tif"));

		if (matches(filelist[i],"^"+prefix+"_s[0-9]+z[0-9]+c[0-9]+m[0-9]+_ORG\.tif$")) {
			if (!set_format){
				format = "SZCM";
				set_format = true;
			}
			// Tile region index
			s = parseInt(substring(metastring, indexOf(metastring, "s") + 1, indexOf(metastring, "z")));
			Sarray = Array.concat(Sarray, s);
			// Stack index
			z = parseInt(substring(metastring, indexOf(metastring, "z") + 1, indexOf(metastring, "c")));
			Zarray = Array.concat(Zarray, z);
			// Channel index
			c = parseInt(substring(metastring, indexOf(metastring, "c") + 1, indexOf(metastring, "m")));
			Carray = Array.concat(Carray, c);
			// Tile index
			m = parseInt(substring(metastring, indexOf(metastring, "m") + 1, lengthOf(metastring)));
			Marray = Array.concat(Marray, m);
			// Filelist index
			Iarray = Array.concat(Iarray, i);
		}
		if (matches(filelist[i],"^"+prefix+"_z[0-9]+c[0-9]+m[0-9]+_ORG\.tif$")) {
			if (!set_format){
				format="ZCM";
				set_format = true;
			}
			// Tile region index
			s = 1;
			Sarray = Array.concat(Sarray, s);
			// Stack index
			z = parseInt(substring(metastring, indexOf(metastring, "z") + 1, indexOf(metastring, "c")));
			Zarray = Array.concat(Zarray, z);
			// Channel index
			c = parseInt(substring(metastring, indexOf(metastring, "c") + 1, indexOf(metastring, "m")));
			Carray = Array.concat(Carray, c);
			// Tile index
			m = parseInt(substring(metastring, indexOf(metastring, "m") + 1, lengthOf(metastring)));
			Marray = Array.concat(Marray, m);
			// Filelist index
			Iarray = Array.concat(Iarray, i);
		}
		if (matches(filelist[i],"^"+prefix+"_s[0-9]+z[0-9]+m[0-9]+_ORG\.tif$")) {
			if (!set_format){
				format = "SZM";
				set_format = true;
			}
			// Tile region index
			s = parseInt(substring(metastring, indexOf(metastring, "s") + 1, indexOf(metastring, "z")));
			Sarray = Array.concat(Sarray, s);
			// Stack index
			z = parseInt(substring(metastring, indexOf(metastring, "z") + 1, indexOf(metastring, "m")));
			Zarray = Array.concat(Zarray, z);
			// Channel index
			c = 1;
			Carray=Array.concat(Carray, c);
			// Tile index
			m = parseInt(substring(metastring, indexOf(metastring, "m") + 1, lengthOf(metastring)));
			Marray = Array.concat(Marray, m);
			// Filelist index
			Iarray = Array.concat(Iarray, i);
		}
		if (matches(filelist[i],"^"+prefix+"_z[0-9]+m[0-9]+_ORG\.tif$")) { //if only 1 scene in CZI
			if (!set_format){
				format = "ZM";
				set_format = true;
			}
			// Tile region index
			s = 1;
			Sarray = Array.concat(Sarray, s);
			// Stack index
			z = parseInt(substring(metastring, indexOf(metastring, "z") + 1, indexOf(metastring, "m")));
			Zarray = Array.concat(Zarray, z);
			// Channel index
			c = 1;
			Carray = Array.concat(Carray, c);
			// Tile index
			m = parseInt(substring(metastring, indexOf(metastring, "m") + 1, lengthOf(metastring)));
			Marray = Array.concat(Marray, m);
			// Filelist index
			Iarray = Array.concat(Iarray, i);
		}
	}
}

Array.getStatistics(Sarray, Smin, Smax, null, null);
Array.getStatistics(Zarray, null, Zmax, null, null);
Array.getStatistics(Carray, null, Cmax, null, null);
Array.getStatistics(Marray, null, Mmax, null, null);

/*
Table.create("dimensions");
Table.showRowNumbers(true);
Table.setColumn("S", Sarray);
Table.setColumn("Z", Zarray);
Table.setColumn("C", Carray);
Table.setColumn("M", Marray);
//Table.sort("S");
Table.update;
*/

Sarray_unique = ArrayUnique(Sarray);

// for each tile region in this dataset
for (i_SU = 0; i_SU < Sarray_unique.length; i_SU++) {
	TileRegion_Mlist = newArray();
	print("Tile region: " + i_SU + " of: " + Sarray_unique.length);
	// for this tile region fetch tile indexes
	for (i = 0; i < Sarray.length; i++) {
		// find any tile index within this region only if first channel and first slice
		if (Sarray_unique[i_SU] == Sarray[i] && Carray[i] == 1 && Zarray[i] == 1) {
			TileRegion_Mlist = Array.concat(TileRegion_Mlist, Marray[i]);
		}
	}
	// for each tile in this tile region
	for (i_M = 0; i_M < TileRegion_Mlist.length; i_M++) {
		// open and stack
		s = Sarray_unique[i_SU];
		m = TileRegion_Mlist[i_M];

		//print("M: " + m);
		for (c = 1; c < Cmax + 1; c++) {
			// list of files to open
			templist = newArray();
			for (z = 1; z < Zmax + 1; z++) {
				// Deal with leading 0 in dimensions for expected filename
				fixeds = leading_zero(s, Smax);
				fixedm = leading_zero(m, Mmax);
				fixedz = leading_zero(z, Zmax);
				fixedc = leading_zero(c, Cmax);

				if (format == "SZCM"){
					filename = prefix + "_s" + fixeds + "z" + fixedz + "c" + fixedc + "m" + fixedm + "_ORG.tif";
				}
				if (format == "ZCM"){
					filename = prefix + "_z" + fixedz + "c" + fixedc + "m" + fixedm + "_ORG.tif";
				}
				if (format == "SZM"){
					filename = prefix + "_s" + fixeds + "z" + fixedz + "m" + fixedm + "_ORG.tif";
				}
				if (format == "ZM"){
					filename = prefix + "_z" + fixedz + "m" + fixedm + "_ORG.tif";
				}

				templist = Array.concat(templist, filename);
				Array.sort(templist);
				//print(directory + filename);
				open(directory + filename);
			}
			//Array.show(templist);

			// make stack for current channel & tile & tile region
			concatenateString = "";
			for (j = 0; j < lengthOf(templist); j++) {
				if (j == 0){ //initiate stack
					concatenateString = "  title=["+s + "_" + m + "_" + c+"] ";
				}
				concatenateString = concatenateString + "image" + j + 1 + "=["+templist[j]+"] ";
			}
			run("Concatenate...", "["+concatenateString+"]");

			// save stack
			selectWindow(s + "_" + m + "_" + c);
			saveAs("tiff", exportpath + prefix + "_S" + s + "_C" + c + "_M" + leading_zero(m, 100) + ".tiff");
			close();

			// remove single tiff files
			if (delete) {
				for (k = 0; k < lengthOf(templist); k++) {
					dummy = File.delete(directory + "/" + templist[k]);
				}
			}
		}
	}
}

print("Done with all tile regions");

function leading_zero(x, maxx) {
	if (maxx < 100) {
		if (maxx < 10) {
			fx = x;
		} else {
			if (x < 10) {
				fx = "0" + x;
			} else {
				fx = x;
			}
		}
	} else {
		if (x < 100) {
			if (x < 10) {
				fx = "00" + x;
			} else {
				fx = "0" + x;
			}
		} else {
			fx = x;
		}
	}
	return fx;
}

function ArrayUnique(input) {
	array = Array.copy(input);
	Array.sort(array);
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
