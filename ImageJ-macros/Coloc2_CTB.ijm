//select a directory with ROIs you want to perform colocalization analysis on
dir = getDirectory("Choose a source directory with ROIs to perform colocalzation analysis on");
list = getFileList(dir);
Array.print(list);
print("Processing images from: " + dir)
occ_list = Array.filter(list, "occludin.tif");
mrp_list = Array.filter(list, "mrp2.tif");
list = Array.concat(occ_list, mrp_list);
list = Array.sort(list);
//create a folder to save the processed files
outDir = dir + "coloc2_results";
File.makeDirectory(outDir);
print("Saving results to: " + outDir);
if (isOpen("Log")) {
	print("\\Clear");
}

//allows the macro run in the background without opening images; comment out to troubleshoot
setBatchMode(true);

for (i=0; i<list.length; i=i+2) {
	open(dir + list[i]);
	open(dir + list[i+1]);
	filename = list[i];
	prefix = substring(filename,0,lastIndexOf(filename, "_")); // remove .tif from name
	done = File.exists(outDir + "/" + prefix + "-coloc2.txt");
	if (done == 0) {
		print("Working on: " + prefix);
		run("Coloc 2", "channel_1=" + prefix + "_occludin.tif channel_2=" + prefix + "_mrp2.tif roi_or_mask=<None> threshold_regression=Costes manders'_correlation costes'_significance_test psf=3 costes_randomisations=200");
		selectWindow("Log");
		run("Text...", "save=[" + outDir + "/" + prefix + "-coloc2.txt]");
		selectWindow("Log");
		print("\\Clear");
		close(list[i]);
		close(list[i+1]);
	} else {
		print("Found coloc2 results for " + prefix + ".");	
	}
}