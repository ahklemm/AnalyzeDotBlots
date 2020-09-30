//DotBlotAnalysis.ijm
//simplifies use of "Landmark Correspondences" plugin to analyse dot blots.
//subtracts background and inverts the original image before analysis.
//input: original image of membrane to be analyzed and maskImage. Mask is a labelledMask of the dot array.
//output: saves in the original folder: results (_results.xls), control image (_detectedWells.tif), saved roi-manager (_ROIs.zip)
//anna.klemm@it.uu.se, BioImage Informatics Facility, SciLifeLab, Sweden.


#@ String(label="Name of the mask-Image", description="Enter the name of the labelled mask encoding the blot array") maskName;
#@ Integer (label="Prominence",value=5) findMax_prom

//gaussian to spotsize

//Preparation

//specific preparation
if (nImages <2) exit("Please open " + maskName + " and your dot-blot image.");
if (nImages>2) waitForUser("Please close all other images and press OK");


//make sure that the dot-blot is the active window, by putting behind the maskImage
selectWindow(maskName);
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

//ask for spotsize: all spot-ROIs will set to equal size
Dialog.create("Spot Analyzer");
Dialog.addMessage("The macro will create circular ROIs with equal diameter above each spot. ");
Dialog.addNumber("Spot diameter (px)", 14);
Dialog.show();
spotsize = Dialog.getNumber();

//delete ROIs in roiManager, if present
roiManager("reset");

//clear Results-window
run("Clear Results");

//register the mask to the image of the dot-blot
//get starting mask using "Landmark Correspondences"
setTool("multipoint");
setBackgroundColor(0 , 0 , 0);
selectWindow(maskName);
run("glasbey_on_dark");
waitForUser("Select 4-5 landmarks in each image:\n1) Select the corresponding landmarks in the same order in the blot to be analyzed and the template.\n2) Click OK ");
selectWindow(maskName);
run("Grays");
//run Landmark Correspondence to obtain a rough mask
run("Landmark Correspondences", "source_image=" + maskName + " template_image=[" + title + "] transformation_method=[Moving Least Squares (non-linear)] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
//rename the image
selectWindow("Transformed" + maskName);
rename("Transformation1_" + maskName);


//threshold the transformed mask (transformation creates non-binary image)
selectWindow("Transformation1_" + maskName);
run("Duplicate...", "title=" + "Transformation1_Thres.tif");
setThreshold(1, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Watershed");
//get ROIs of single wells by analyze particles
run("Analyze Particles...", "add");
//create a gaussian-blurred copy of the original blot to achieve better results with "Find Maxima"
selectWindow(title);
run("Duplicate...", "title=DotBlot_gaussian");
run("Gaussian Blur...", "sigma=2");



/* find more landmarks to obtain a more precise transformation mask:
 * original dot-blot (title) is gaussian filtered. Maxima are searched within ROIs obtained with the transformed mask. 
 * When a maximum was found, the point is taken as a landmark for the second, finer transformation step.  
 * ROIs that gave a maximum in the title-image are noted. Centroids of these ROIs are the landmarks on the mask.
*/

//searching for clear-dot signals within the well-ROIs:
//iterate over ROIs from mask and run "Find Maxima" within the selection.
//make array with coordinates
//creates a results-table with: X, Y, and spot-ID of the ROI in which the landmark was found

xoriginal = newArray(); //xoriginal and yoriginal store the positions of maxima (original image) that can be used as landmarks
yoriginal = newArray(); 
xmask = newArray(); //xmask and ymask stort positions of the corresponding spot-centers as landmarks within the mask image.
ymask = newArray();


selectWindow("DotBlot_gaussian");

for(spot = 0; spot < roiManager("count"); spot++){
	//select a spot
	roiManager("select", spot);
	//search for maxima within the spot
	run("Find Maxima...", "prominence=" + findMax_prom +" exclude output=[Point Selection]");
	selection = selectionType(); 
	if(selection==10){ //only when selection is a point-selection
		Roi.getCoordinates(xpoints, ypoints);
		if(xpoints.length == 1){  //collect as landmark only if only one maximum was found
			// get precise position of peak in the image
			xoriginal = Array.concat(xoriginal , xpoints[0]);
			yoriginal = Array.concat(yoriginal , ypoints[0]);
			
			//get the x,y position of the spot center
			roiManager("select", spot);
			x = getValue("X");
			y = getValue("Y");
			xmask = Array.concat(xmask , x);
			ymask = Array.concat(ymask , y);
		}
	}
}


//Display Maxima/Centroid-position on the original images
selectWindow(title);
makeSelection("point", xoriginal, yoriginal);

selectWindow("Transformation1_" + maskName);
makeSelection("point", xmask, ymask);


//run Landmark Correspondences, now with more markers
selectWindow(maskName);
close();
run("Landmark Correspondences", "source_image=" + "[Transformation1_" + maskName + "] template_image=[" + title + "] transformation_method=[Moving Least Squares (non-linear)] alpha=1 mesh_resolution=32 transformation_class=Affine interpolate");
//rename
selectWindow("Transformed" + "Transformation1_" + maskName);
rename("Transformation2_" + maskName);


/*
 * Work with final transformed mask
 */

 
//binarize newly transformed mask and get ROIs of the final transformed mask
roiManager("Reset");
run("Duplicate...", "title=Transformation2_Thres.tif");
selectWindow("Transformation2_Thres.tif");
setThreshold(1, 255);
setOption("BlackBackground", true);
run("Convert to Mask");
run("Watershed");
run("Analyze Particles...", "add");




//get centroids, make new equally sized ROIs, update manager and rename
IDnames = createSpotIDArray(); //createSpotIDArray() creates an array that contains the names of each spot

setBatchMode(true);
for(r = 0; r < roiManager("Count"); r++){
	//extract the final coordiantes and draw a "fresh" ROI
	selectWindow("Transformation2_Thres.tif");
	roiManager("Select", r);
	final_x = getValue("X");
	final_y = getValue("Y");
	run("Specify...", "width=" + spotsize + " height=" + spotsize + " x=" + final_x + " y=" + final_y + " oval centered");
	roiManager("Update");

	// get spot-IDs
	selectWindow("Transformation2_" + maskName); //select the colorcoded mask to find out spot-id
	//smaller ROI for finding the ID, since interpolation can create different gray values especially at the edge of the ROI
	run("Specify...", "width=" + round(spotsize/2) + " height=" + round(spotsize/2) + " x=" + final_x + " y=" + final_y + " oval centered");
	getStatistics(areaR, ROI_ID, minR, maxR, stdR, histogramR);  //measuring the (transformed) labelled mask gives the ROI-ID; labelled mask starts with 1
	ROI_ID_norm = ROI_ID - 1;  //ROI-IDs start with 1 --> subtract 1 for indexing the IDnames array
	roiManager("Rename", IDnames[ROI_ID_norm]);
}

setBatchMode(false);
roiManager("Sort");



//clean-up
close("Transformation1_" + maskName);
close("Transformation1_Thres.tif");
close("Transformation2_" + maskName);
close("Transformation2_Thres.tif");
close("DotBlot_gaussian");


//measure on inverted, background subtracted image
	
run("Set Measurements...", "area mean min centroid integrated display redirect=None decimal=1");
selectWindow(title);
run("Subtract Background...", "rolling=" + 3 * spotsize); //radius of background subtraction is 3 * the entered spotsize
setBatchMode("show");
roiManager("Show All without labels");
waitForUser("Possibility to modify and update single ROIs");
	
roiManager("deselect");  //preparation to measure all ROIs
roiManager("Measure");	//measures all ROIs if no ROI is selected


//saving the result
saveAs("results", path_prefix + "_results.xls");
selectWindow(title);
roiManager("Show All without labels");
run("Flatten");
saveAs("tiff", path_prefix +"_detectedWells.tif");
roiManager("save", path_prefix + "_ROIs.zip");

//clean up
close(title);

/* function createSpotIDArray
 * creates an array that contains the spot-labels of each spot
*/ 
function createSpotIDArray(){

	A = newArray(24);
	B = newArray(20);
	C = newArray(20);
	D = newArray(24);
	E = newArray(24);
	F = newArray(24);
	G = newArray(24);
	H = newArray(24);
	I = newArray(22);
	J = newArray(12);
	
	
	for(full=1; full<=24; full++){
		if(full<10){
			A[full-1] = "A0"+full;
			D[full-1] = "D0"+full;
			E[full-1] = "E0"+full;
			F[full-1] = "F0"+full;
			G[full-1] = "G0"+full;
			H[full-1] = "H0"+full;
		} else {
			A[full-1] = "A"+full;
			D[full-1] = "D"+full;
			E[full-1] = "E"+full;
			F[full-1] = "F"+full;
			G[full-1] = "G"+full;
			H[full-1] = "H"+full;
		}
	}
	
	counter = 0;
	for(bc=3; bc<=22; bc++){
		if(bc<10){
			B[counter] = "B0"+bc;
			C[counter] = "C0"+bc;
		counter++;
		}else {
			B[counter] = "B"+bc;
			C[counter] = "C"+bc;
			counter++;
		}
	}
	
	
	for(i=1; i<=22; i++){
		if(i<10){
			I[i-1] = "I0"+i;
		}else {
			I[i-1] = "I"+i;
		}
		
	}
	
	J[0] = "J01";
	J[1] = "J02";
	counter = 2;
	for(j=5; j<=12; j++){
		if(j<10){
			J[counter] = "J0"+j;
			counter++;
		}else{
			J[counter] = "J"+j;
			counter++;
		}
	}
	J[10] = "J23";
	J[11] = "J24";
	
	ID_Array = Array.concat(A, B, C, D, E, F, G, H, I, J);

	return ID_Array;
}


