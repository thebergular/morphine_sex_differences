//allows the macro run in the background without opening images; comment out to troubleshoot
//setBatchMode(true);

//select a directory with czi files you want to process
dir = getDirectory("Choose Source Directory");
list = getFileList(dir);
print("Processing files from: " + dir)
//create a folder to save the processed files
outDir = dir + "MAXproj";
File.makeDirectory(outDir);
print("Saving new files to: " + outDir);
csvDir = outDir + "/CSVs";
File.makeDirectory(csvDir);

for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "_fitc-denoised.tif")) {
		run("Clear Results");
		roiManager("reset");
		print("Processing file: "+list[i]); //print the file being processed
		open(dir+list[i]);
		name = getTitle();
		prefix = substring(name,0,indexOf(name, ".")); // remove .tif from name
		// Create binary mask
		maskmade = File.exists(outDir + "/" + prefix + "_MAX-mask.tif");
		if (maskmade == 0) {
			waitForUser("choose slices for z-projection");
			run("Z Project...");
			saveAs("tiff", outDir + "/" + prefix + "_MAX.tif");
			selectWindow(prefix + "_MAX.tif");
			run("Duplicate...", "duplicate");
			setAutoThreshold("Li dark");
			run("Convert to Mask", "method=Li background=Dark black create");
			run("Dilate");
			run("Fill Holes");
			run("Erode");
			//make composite of mask + blurred to assess fit
			run("Merge Channels...", "c1=" + prefix + "_MAX-1.tif c2=" + prefix + "_MAX.tif create keep ignore");
			waitForUser("check masks, no crazy 'holes' filled; leave only 1 mask open");
			selectWindow(prefix + "_MAX-1.tif");
			saveAs("tiff", outDir + "/" + prefix + "_MAX-mask.tif");
			} else {
				open(outDir + "/" + prefix + "_MAX-mask.tif");
				print("Found mask of MAX projection");	
			}
		selectWindow(prefix + "_MAX-mask.tif"); 
		roisdrawn = File.exists(outDir + "/" + prefix + "_MAX-ROIs.zip");
		if (roisdrawn == 0) {
			waitForUser("manually fill/separate vessels");
			setOption("BlackBackground", true);
			run("Convert to Mask");
			roiManager("reset");
			roiManager("Show None");
			run("Set Measurements...", "redirect=None decimal=2");
			run("Analyze Particles...", "size=50.00-Infinity circularity=0.00-0.80 add composite");
			run("Clear Results");
			waitForUser("fix up and name ROIs (type#-inside, e.g. A1-inside (A=arteriole, V=venule, etc)");
			//get "outside" of each ROI
			//want to add code to skip images with finished ROIs
			precount = roiManager("count");
			for (j=0; j<precount; j++) {
				roiManager("Select", j);
				roiname = Roi.getName();
				roisubname = substring(roiname,0,indexOf(roiname, "-")); // remove "inside" from name
				run("Enlarge...", "enlarge=3");
				Roi.setName(roisubname);
				roiManager("Add");
				roiManager("Select", newArray(RoiManager.getIndex(roiname),RoiManager.getIndex(roisubname)));
				roiManager("XOR");
				Roi.setName(roisubname + "-outside");
				roiManager("Add");
				postcount = roiManager("count");
				array = newArray(postcount);
		 			for (p=0; p<array.length; p++) {
		      			array[p] = p;
		  			}
				//save ROIs
				roiManager("select", array);
				roiManager("save", outDir + "/" + prefix + "_MAX-ROIs.zip");
				run("Clear Results");
				}
		} else {
			print("Found saved ROIs for this image");	
			open(outDir + "/" + prefix + "_MAX-ROIs.zip");
		}
		roismeas = File.exists(csvDir + "/" + prefix + "-Results.csv");
		if (roismeas == 0) {
			//measure ROIs
			run("Clear Results");
			open(outDir + "/" + prefix + "_MAX.tif");
			postcount2 = roiManager("count");
			array2 = newArray(postcount2);
		 		for (q=0; q<array2.length; q++) {
		      			array2[q] = q;
		  			}
			roiManager("select", array2);
			run("Set Measurements...", "area mean min area_fraction display redirect=" + prefix + "_MAX.tif decimal=2");
			roiManager("Measure");
			saveAs("Results", csvDir + "/" + prefix + "-Results.csv");
		} else {
			print("Found CSV of measured ROIs for this image");	
		}
		run("Clear Results");
		roiManager("reset");
		close("*");
	}
}