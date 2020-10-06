# DotBlotAnalysis.ijm
ImageJ macro scripts to measure intensities in dot blots in e.g. protein arrays.

## Documentation DotBlotAnalysis.ijm
* Simplifies the intensity measurements of dot blots in e.g. protein arrays.
* subtracts background and inverts the original image before analysis.
* input: original image of membrane to be analyzed and mask image. The mask image is a labelledMask of the dot array.
* output: saves in the original folder: results table (_results.xls), control image (_detectedWells.tif), saved roi-manager (_ROIs.zip)
* author: Anna Klemm
* connected forum.image.sc thread: https://forum.image.sc/t/dot-blot-analysis/7106

The image of the dot blot was provided by Katja Eubler, Mayerhofer-lab, BMC, LMU Munich, Germany.
Code and example images are available under the creative common licence CC BY SA.
