//Translates a schematic draw of a DotBlot Array into a labelled mask used for DotBlotAnalysis.ijm
//input: schematic representation of the Array by vendor
//output: labelled mask, called "Panel.tif"
//created by: anna.klemm@it.uu.se, BioImage Informatics Facility, SciLifeLab, Sweden.
//December 2018

//preparations
path_output = getDirectory("Choose a Directory for Saving the Image");
run("Options...", "iterations=1 count=1 black do=Nothing");

//get approximate size of the dots
waitForUser("Draw a circle around one of the Dots");
getStatistics(DotArea, mean, min, max, std, histogram);
run("Select None");

//binarize
run("8-bit");
setAutoThreshold("Default dark");
run("Convert to Mask");

//get dots
run("Analyze Particles...", "size=" + DotArea *0.8 + "-Infinity circularity=0.90-1.00 show=[Count Masks]");
run("glasbey_on_dark");
rename("Panel.tif");

//save
saveAs("tiff", path_output + "Panel.tif");
