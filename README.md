# DotBlot_Analysis.ijm
ImageJ macro script to measure intensities in dot blots in e.g. protein arrays.

* Simplifies the intensity measurements of dot blots in e.g. protein arrays.
* subtracts background and inverts the original image before analysis.
* input: original image of membrane to be analyzed and mask image. The mask image is a labelledMask of the dot array.
* output: saves in the original folder: results table (_results.xls), control image (_detectedWells.tif), saved roi-manager (_ROIs.zip)
* contact for help: forum.image.sc - link to @aklemm

The image of the dot blot was provided by Katja Eubler, Mayerhofer-lab, BMC, LMU Munich, Germany.
//The code can be re-used according to license: BSD-3-Clause.
