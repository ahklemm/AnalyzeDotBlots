//DotBlotAnalysis.ijm
//simplifies use of "Landmark Correspondences" plugin to analyse dot blots.
//subtracts background and inverts the original image before analysis.
//input: original image of membrane to be analyzed and maskImage. MaskImage is a labelledMask of the dot array.
//output: saves in the original folder: results (_results.xls), control image (_detectedWells.tif), saved roi-manager (_ROIs.zip)
//created by A.Klemm, bioimaging@med.lmu.de at BMC, LMU Munich, Germany
//current address: anna.klemm@it.uu.se, BioImage Informatics Facility, SciLifeLab, Sweden.

//maskImage = "HumanXLCytokineArray.tif";
maskImage = "Panel.tif";



//Preparation

//specific preparation
if (nImages!=2) exit("Please open " + maskImage + " and your dot-blot image.");
if (nImages>2) waitForUser("Please close all other images and press OK");


//make sure that the dot-blot is the active window, by putting behind the maskImage
selectWindow(maskImage);
mask_id = getImageID();
run("Put Behind [tab]");

//get dot-blot filename and path for saving
dotblot_id = getImageID();
title=getTitle();
dot = lastIndexOf(title, ".");
titlePure = substring(title, 0, dot);
origin = getDirectory("image");
path_prefix = origin + titlePure;

//invert dot-blot
selectImage(dotblot_id);
run("Invert");

//preparations
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");
getDimensions(width, height, channels, slices, frames);	

//spotsize: all spot-ROIs will set to equal size
Dialog.create("Spot Analyzer");
Dialog.addMessage("The macro will create circular ROIs with equal diameter above each spot. ");
Dialog.addNumber("Spot diameter (px)", 14);
Dialog.show();
spotsize = Dialog.getNumber();

//delete ROIs in roiManager, if present
roiManager("reset");

//close Results-window, if present
if(isOpen("Results")){
	selectWindow("Results");
	run("Close");
}

//register the mask to the image of the dot-blot
//get starting mask using "Landmark Correspondences"
setTool("multipoint");
waitForUser("Select 4-5 landmarks in each image:\n1) Select the corresponding landmarks in the same order in the blot to be analyzed and the template.\n2) Click OK ");
//run Landmark Correspondence to obtain a rough mask
run("Landmark Correspondences", "source_image=" + maskImage + " template_image=[" + title + "] transformation_method=[Moving Least Squares (non-linear)] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");

//threshold the transformed mask (rotation creates non-binary image)
selectWindow("Transformed" + maskImage);
run("Duplicate...", "title=" + maskImage + "_forThres.tif");
setThreshold(1, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Watershed");
//get single wells by analyze particles
run("Set Measurements...", "area mean min centroid fit redirect=None decimal=1");
run("Analyze Particles...", "add");
selectWindow("Transformed" + maskImage);
rename("mask_original");
//create a gaussian-blurred copy of the original blot to achieve better results with "Find Maxima"
selectWindow(title);
run("Duplicate...", "title=gaussian");
run("Gaussian Blur...", "sigma=2");

/* create more landmarks to obtain a more precise transformation mask:
 * original dot-plot (title) is gaussian filtered. Maxima are searched within ROIs obtained with the transformed mask. 
 * When a maximum was found, the point is taken as a landmark for the second, finer transformation step.  
 * ROIs that gave a maximum in the title-image are noted. Centroids of these ROIs are the landmarks on the mask.
 */

//searching for clear-dot signals in the positions
//iterate over ROIs from mask and run "Find Maxima" within the selection.
//make array with coordinates
selectWindow("gaussian");
counter = 0;
	for(i=0; i<roiManager("count"); i++){
		roiManager("select", i);
		run("Set Measurements...", "centroid redirect=None decimal=1");
		run("Find Maxima...", "prominence=5 exclude output=[Point Selection]");
		pointSelection = selectionType(); 
		if(pointSelection==10){ //only when selection is a point-selection
			Roi.getCoordinates(xpoints, ypoints);
			if(xpoints.length == 1){  //excludes if more than one maxima was found
				run("Measure");
				setResult("ROI-Index", counter, i);
				counter++;
			}
		}
		
	}
updateResults();

transformationPoints = nResults;
	
xoriginal = newArray(transformationPoints );
yoriginal = newArray(transformationPoints );
xmask = newArray(transformationPoints );
ymask = newArray(transformationPoints );
index = newArray(transformationPoints);



//iterate over result table and extract X and Y of the dots in the original image (dot blot)
for(r=0; r<transformationPoints ; r++){
	xoriginal[r] = getResult("X", r);
	yoriginal[r] = getResult("Y", r);
	index[r] = getResult("ROI-Index", r);
}

	
	


//get centroids of Mask ROIs to obtain landmarks for the mask.
run("Clear Results");
for(i=0; i<roiManager("count"); i++){
	roiManager("select", i);
	run("Measure");
}
updateResults();

//extract the X,Y-coordinates of those ROIs that have a maximum; index[];
for(r=0; r<transformationPoints; r++){
	xmask[r] = getResult("X", index[r]);
	ymask[r] = getResult("Y", index[r]);
}

//Display Maxima/Centroid-position on the original images
selectWindow(title);
makeSelection("point", xoriginal, yoriginal);

selectWindow("mask_original");
makeSelection("point", xmask, ymask);

//run Landmark Correspondences, now with more markers
selectWindow(maskImage);
close();
//waitForUser("check");
run("Landmark Correspondences", "source_image=mask_original template_image=[" + title + "] transformation_method=[Moving Least Squares (non-linear)] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");


/*
 * Work with final transformed mask
 */
 
//binarize newly transformed mask and get ROIs of the final transformed mask
roiManager("Reset");
run("Duplicate...", "title=Transformedmask_thres");
selectWindow("Transformedmask_thres");
setThreshold(1, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Watershed");
run("Analyze Particles...", "add");


//get centroids, make new equally sized ROIs, update manager and rename
IDnames = createSpotIDArray(); //createSpotIDArray() creates an array that contains the names of each spot
run("Set Measurements...", "mean centroid redirect=None decimal=1");
setBatchMode(true);
run("Clear Results");
for(r=0; r<roiManager("Count"); r++){
	selectWindow("Transformedmask_thres");
	roiManager("Select", r);
	run("Measure");
	final_x = getResult("X", 0);
	final_y = getResult("Y", 0);
	run("Specify...", "width=" + spotsize + " height=" + spotsize + " x=" + final_x + " y=" + final_y + " oval centered");
	roiManager("Update");
	selectWindow("Transformedmask_original"); //select the colorcoded mask to find out spot-id
	//smaller ROI for finding the ID, since interpolation can create different gray values especially at the edge of the ROI
	run("Specify...", "width=" + round(spotsize/2) + " height=" + round(spotsize/2) + " x=" + final_x + " y=" + final_y + " oval centered");
	run("Measure");
	ROI_ID = getResult("Mean", 1); //measuring the (transformed) labelled mask gives the ROI-ID; labelled mask starts with 1
	ROI_ID_norm = ROI_ID - 1;  //ROI-IDs start with 1 --> subtract 1 for indexing the IDnames array
	run("Clear Results");
	roiManager("Rename", IDnames[ROI_ID_norm]);
}

setBatchMode(false);
roiManager("Sort");


//clean-up
close("Transformedmask_thres");
close("Transformedmask_original");
close("mask_original");
close("gaussian");
close(maskImage+"_forThres.tif");




//measure on inverted, background subtracted image
	
run("Set Measurements...", "area mean min centroid integrated display redirect=None decimal=1");
selectWindow(title);
run("Subtract Background...", "rolling="+3*spotsize); //radius of background subtraction is 3 * the entered spotsize
setBatchMode("show");
roiManager("Show All without labels");
waitForUser("Possibility to modify and update single ROIs");
	
roiManager("deselect");  //preparation to measure all ROIs
roiManager("Measure");	//measures all ROIs if no ROI is selected
//clean up
close("gaussian");
close("mask_original");
	
//saving the result
saveAs("results", path_prefix + "_results.xls");
selectWindow(title);
roiManager("Show All without labels");
run("Flatten");
saveAs("tiff", path_prefix +"_detectedWells.tif");
roiManager("save", path_prefix + "_ROIs.zip");


/* function createSpotIDArray
 * creates an array that contains the spot-labels of each spot
*/ 
function createSpotIDArray(){

	A = newArray("A01", "A02", "A23", "A24");
	B = newArray(24);
	C = newArray(24);
	D = newArray(24);
	E = newArray(8);
	F = newArray("F01", "F02", "F23", "F24");

	for(full=1; full<=24; full++){
		if(full<10){
			B[full-1] = "B0"+full;
			C[full-1] = "C0"+full;
			D[full-1] = "D0"+full;
		
		} else {
			B[full-1] = "B"+full;
			C[full-1] = "C"+full;
			D[full-1] = "D"+full;
		}
	}
	
	for(e=1; e<=8; e++){
		E[e-1] = "E0"+e;
		}
	
	ID_Array = Array.concat(A, B, C, D, E, F);
	return ID_Array;
}


