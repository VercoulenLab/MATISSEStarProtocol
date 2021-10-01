// This script fetches ROI number and description from xml metadata and renames the ome tiff files accordingly

//for call by other macro
if (getArgument()!="") {
	directory = getArgument();
} else {
	print("\\Clear");
	directory = getDirectory("select mcd export folder");
}

makeFolder(directory + "before/");
makeFolder(directory + "after/");

prefix = File.getName(directory);
path_schemaXML = directory + prefix + "_schema.xml"; 

if (File.exists(path_schemaXML)){
	xml_meta = File.openAsString(path_schemaXML);
	
	// ROI info
	xml_meta_Scenes_replaced = replace(xml_meta, "<Acquisition>", "#");
	xml_meta_Scenes_replaced_parts = split(xml_meta_Scenes_replaced, "#");
	for (i = 1; i < xml_meta_Scenes_replaced_parts.length; i++) {
		ROI_string = xml_meta_Scenes_replaced_parts[i];
		ROI_ID = fetchParameterXML(ROI_string, "ID");
		ROI_Description = fetchParameterXML(ROI_string, "Description");
		ROI_AcquisitionROIID = fetchParameterXML(ROI_string, "AcquisitionROIID");
		ROI_OrderNumber = fetchParameterXML(ROI_string, "OrderNumber");

		path_ROI = directory + prefix + "_s0_a" + ROI_AcquisitionROIID;
		path_ROI_ome = path_ROI + "_ac.ome.tiff";
		path_ROI_ome_new = directory + prefix + "_R-" + ROI_AcquisitionROIID + "_D-" + ROI_Description + ".tiff";
		if (File.exists(path_ROI_ome)) {
			print(path_ROI_ome_new);
			null = File.rename(path_ROI_ome, path_ROI_ome_new);
		}
		path_ROI_before = path_ROI + "_before.png";
		path_ROI_before_new = directory + "before/" + prefix + "_R-" + ROI_AcquisitionROIID + "_D-" + ROI_Description + "_before.png";
		path_ROI_after = path_ROI + "_after.png";
		path_ROI_after_new = directory + "after/" + prefix + "_R-" + ROI_AcquisitionROIID + "_D-" + ROI_Description + "_after.png";
		
		if (File.exists(path_ROI_before)) {
			null = File.rename(path_ROI_before, path_ROI_before_new);
			null = File.rename(path_ROI_after, path_ROI_after_new);
		}
	}
}

function indexOfEnd(string, subString) { 
	index = indexOf(string, subString) + lengthOf(subString);
	return index;
}

function fetchParameterXML(string, name) {
	delimeter_start = "<" + name + ">";
	delimeter_end = "</" + name + ">";
	
	output = substring(string, indexOfEnd(string, delimeter_start), indexOf(string, delimeter_end));
	return output;
}

function makeFolder(path) {
	if (!File.exists(path)) {
		File.makeDirectory(path);
	}
}
