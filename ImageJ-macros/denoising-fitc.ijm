// Macro for quantifying BBB/BRB leak

//allows the macro run in the background without opening images; comment out to troubleshoot
//setBatchMode(true);

run("Bio-Formats Macro Extensions");

//select a directory with czi files you want to process
dir = getDirectory("Choose Source Directory with files to analyze");
list = getFileList(dir);
print("Processing files from: " + dir)
//create a folder to save the processed files
outDir = dir + "processing";
File.makeDirectory(outDir);
print("Saving new files to: " + outDir);

// for each file in directory
for (f=0; f<list.length; f++) {
	filename = dir + list[f];
	bfi = "open=["+filename+"] autoscale split_channels color_mode=Colorized display_rois rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT";
	// from raw files only
	if (endsWith(filename, ".czi")) {
		run("Bio-Formats Importer", bfi);
		name = getTitle();
		print(name);
		subname = substring(name,0,indexOf(name, " ")); // remove channel info from name
		print(subname);
		prefix = substring(subname,0,indexOf(subname, ".")); // remove file extension from name
		print(prefix);
		//pre-processing (if not done)
		denoised = File.exists(outDir + "/" + prefix + "_fitc-denoised.tif");
		if (denoised == 0) {
			setSlice(3);
			run("Subtract Background...", "rolling=25 stack");
			run("Remove Outliers...", "radius=3 threshold=10 which=Bright stack");
			run("Despeckle", "stack");
			run("Enhance Contrast", "saturated=0.1");
			saveAs("tiff", outDir + "/" + prefix + "_fitc-denoised.tif");
			} else {
			open(outDir + "/" + prefix + "_fitc-denoised.tif");
			print("FITC already denoised");	
			}
		
	}
}

