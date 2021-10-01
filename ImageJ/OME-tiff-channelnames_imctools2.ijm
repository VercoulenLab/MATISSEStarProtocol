print("\\Clear");
title = getTitle();
ID = getImageID();
path = getDirectory("image");

//generic_name = substring(title, 0, lastIndexOf(title, "_s"));
generic_name = File.getName(path);

if (matches(title, "^.+(_a)[0-9]+(_ac.ome.tiff)$")) {
	region_number = substring(title, indexOf(title, "_a", lengthOf(generic_name)) + 2, lastIndexOf(title, "_ac"));
}
if (matches(title, "^.+(_R-)[0-9]+(_D-).+(.tiff)$")) {
	region_number = substring(title, indexOf(title, "_R-", lengthOf(generic_name)) + 3, indexOf(title, "_D-"));
}

xml_file_path = path + generic_name + "_schema.xml";

if (File.exists(xml_file_path)) {
	xml_content = File.openAsString(xml_file_path);
	channel_names_table_name = FetchChannels(xml_content, region_number);
	SetNames(channel_names_table_name, ID);
} else {
	showMessage("No XML file found!");
}

function SetNames(channel_names_table_name, ID) {
	ChannelNames = Table.getColumn("ChannelName");
	ChannelLabels = Table.getColumn("ChannelLabel");

	// slices to channels
	Stack.getDimensions(width, height, channels, slices, frames);

	// rename
	for (i = 0; i < slices; i++) {
		Stack.setSlice(i+1);
		Name = ChannelNames[i] + "_" + ChannelLabels[i];
		setMetadata("Label", Name);	
	}
	Stack.setSlice(1);
	selectWindow(channel_names_table_name);
	//run("Close");
}

function FetchChannels(xml_content, region_number) {
	xml_content_lines = split(xml_content, "\n");
	TableName = "Channels";
	Table.create(TableName);
	rowIndex = 0;
	for (i = 0; i < xml_content_lines.length; i++) {
		if (endsWith(xml_content_lines[i], "<AcquisitionChannel>")) {
			// each channel found in XML
			AcquisitionID = XMLSubstring(xml_content_lines[i + 8], "AcquisitionID");
			if (AcquisitionID == region_number) {
				// get info
				ChannelName = XMLSubstring(xml_content_lines[i + 4], "ChannelName");
				if (ChannelName != "X" && ChannelName != "Y" && ChannelName != "Z") {
					ChannelLabel = XMLSubstring(xml_content_lines[i + 10], "ChannelLabel");
					OrderNumber = parseInt(XMLSubstring(xml_content_lines[i + 6], "OrderNumber"));
					// info to table
					Table.set("ChannelName", rowIndex, ChannelName);
					Table.set("ChannelLabel", rowIndex, ChannelLabel);
					Table.set("OrderNumber", rowIndex, OrderNumber);
					rowIndex++;
				}
			}
			i = i + 13;
		}
	}

	Table.update;
	Table.sort("OrderNumber");
	Table.showRowNumbers(true);

	return TableName;
}

function XMLSubstring(string, delimiter) {
	delimiter = "<" + delimiter + ">";
	string = substring(string, indexOf(string, delimiter) + lengthOf(delimiter), indexOf(string, replace(delimiter, "<", "</")));
	return string;
}