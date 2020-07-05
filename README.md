# AnalyzeProteinArrays
ImageJ macro scripts to measure intensities in dot blots in e.g. protein arrays.

## Documentation DotBlotAnalysis.ijm
* Simplifies the intensity measurements of dot blots in e.g. protein arrays.
* subtracts background and inverts the original image before analysis.
* input: original image of membrane to be analyzed and maskImage. MaskImage is a labelledMask of the dot array (more information see below).
* output: saves in the original folder: results table (_results.xls), control image (_detectedWells.tif), saved roi-manager (_ROIs.zip)
* author: Anna Klemm
* connected forum.image.sc thread: https://forum.image.sc/t/dot-blot-analysis/7106

## Guidelines for Adapting to a new Panel
###	1) Create a labelled mask that reflects your panel.
The labelled mask gives an ID to each dot in your array. The spot in the upper left corner needs to have ID = 1, with increasing IDs left to right and top to bottom.

#### Running MaskGenerator.ijm 
For vendor template that looks like shown below you can use the macro script MaskGenerator.ijm. 
![vendor template](/images_for_documentation/example_vendor_template.png)

The MaskGenerator.ijm creates a labelled mask formated as needed for the analysis. That means the output is a labelled mask where the spot A1 has the gray value = 1, A2 has gray value = 2 etc. . 
The output is displayed using the glasbey_on_dark LUT to increase the visibility of each single spot:
![glasbey_output](/images_for_documentation/example_panel.png)

### 2) Adapt the macro DotBlotAnalysis.ijm
The function createSpotIDArray() needs to be adapted for each specific panel.
createSpotIDArray()  starts in the very end of the script at line 235 of DotBlotAnalysis.ijm
*	It creates a simple string array containing the Spot Labels from left to right and top to bottom, e.g. "A01", "A02", "A23", "A24", "B01", "B02", "B03", "B04" ….
* In order to not type all these labels manually the function uses loops to create the labels slightly more conveniently
*	You should know how to handle arrays and loops within the ImageJ macro language. See https://fiji.sc/Introduction_into_Macro_Programming for more information.

Examples from the code:
Example 1: Creates an Array containing all “A”-labels , by manually typing them while creating the array.
```javascript
A = newArray("A01", "A02", "A23", "A24");
```
Example 2
Creates first an empty array for all “B”-labels. The for-loop then fills up the empty array with labels reaching from “B01” to “B24”.
```javascript
B = newArray(24);
for(full=1; full<=24; full++){
		if(full<10){
			B[full-1] = "B0" + full;
			} else {
			B[full-1] = "B" + full;
			}
	}
```
In the end, the single Rows are concatenated to one big Array, which is the output of the createSpotIDArray() function.
```javascript
ID_Array = Array.concat(A, B, C, D, E, F);
```
