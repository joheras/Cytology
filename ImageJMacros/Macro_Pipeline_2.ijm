/*
 * PSYCOTRIP - Universidad de La Rioja
 * 
 * GOAL: show the results of classificacion using the model XXXX and correct or confirm the results by an expert
 *
 * INPUT: 	select the folder with the rois images
 * 			select the csv-file with the results of the classification
 * 			
 * OUTPUT: 	show each image of the experiment and the user correct or confirm the result of the classification
 * 
 * Description:	
 * 
 *
 * Options: 
 * 			change the name of the output folder
 * 			batch mode (true/false)
 * 			
 * 
 * Notes:
 * 		this macro is a colaboration with ZgZ
 *
 * Last Update October 2022
*/

//VARIABLES
batchMode=false; //to enable the background process 

originalPath="D:/004_Proyectos/000_Citología_ZgZ";
outputPath=originalPath+"/Original--Output_Segmentation";
outputFolder="--Output_Segmentation"; //name of the output folder
modelFolder="model";
imgFolder="imgS3_rois";
resultFolder="results";
sendFolder="send";
resultsFile="model/result.csv";

class0="no malign";
class1="malign";

//PROCESS 
print("\\Clear");
setForegroundColor(255, 255, 255);
timeO=getTime();
run("Bio-Formats Macro Extensions");

setBatchMode(batchMode);

originalPath = getDirectory("Choose folder with I files ");
dirIparent = File.getParent(originalPath);
dirIname = File.getName(originalPath);
outputPath = dirIparent+File.separator+dirIname+outputFolder;

//create folders
dirResults = originalPath+File.separator+resultFolder;
if (File.exists(dirResults)==false) {
  	File.makeDirectory(dirResults); // new folder
}
dirSend = originalPath+File.separator+resultFolder+File.separator+sendFolder;
if (File.exists(dirSend)==false) {
  	File.makeDirectory(dirSend); // new folder
}

//get a list with the path of the images
listImages=getFileList(outputPath+File.separator+imgFolder);
Array.sort(listImages);

//open the results-file
path=outputPath+File.separator+resultsFile; //if replace "/" by File.separator it does not work, the name of the table is all
print(path);
open(path);
resultsFile="result.csv";
Table.rename(resultsFile, "Results");
Table.sort("imageName"); //column 1
n=nResults;

//process all images (original images)
nImg=lengthOf(listImages);
print("image, model prediction, num rois, class");
for (i = 0; i < nImg; i++) {
	roiManager("reset");
	if (endsWith(listImages[i], "tif")){ //only images
		
		aux=File.getNameWithoutExtension(listImages[i]);
		pathAux=getResultString("path", 0);
		open(outputPath+File.separator+imgFolder+File.separator+listImages[i]);
		
		if(pathAux.contains(aux)) //image classified as malign //si la imagen corresponde con el primero de la tabla de resultados
		{
			npatches=0;
			row=0;
			esta=true;
			while(esta){
				npatches++;
				Table.deleteRows(0, 0);
				updateResults();
				if(nResults!=0){
					pathAux=getResultString("path", row);
					if(!pathAux.contains(aux))
					{
						esta=false;
					}
				}
				else{
					esta=false;
				}
			}
			yesNo=getBoolean("This image was classifies as "+class1+" by the model. Press 'Yes' if you agree, otherwise press 'No'", "Yes", "No");
			if(!yesNo)
			{
				waitForUser("Checking the image", "Please, check the image. It was classified as "+class1+" by the model. Click 'OK' to continue with the analysis.");
				yesNo=getBoolean("Do you want to correct the classification for this image?. Press 'Yes' if the class of the image is "+class0+", otherwise press 'No'", "Yes", "No");
				if(yesNo)
				{
					print(listImages[i]+", "+class1+", "+npatches+", "+class0);
				}else{
					print(listImages[i]+", "+class1+", "+npatches+", "+class1);
				}
			}else{
				print(listImages[i]+", "+class1+", "+npatches+", "+class1);
			}
		}
		else{ //classified as no malign
			
			open(outputPath+File.separator+imgFolder+File.separator+listImages[i]);
			
			yesNo=getBoolean("This image was classifies as "+class0+" by the model. Press 'Yes' if you agree, otherwise press 'No'", "Yes", "No");
			if(!yesNo)
			{
				waitForUser("Confirm the result", "Please, check the image. It was classified as "+class0+" by the model. \nSelect the malign zone, and, add that roi to the roi manager (use the rectangle area and click 'add'). \nWhen the checking is finished, click 'Ok'");
				nrois=roiManager("count");
				if(nrois!=0) //save the rois and the image (serie 3) in case of the image is bad classified by the model
				{
					roiManager("deselect")
					roiManager("save", originalPath+File.separator+resultFolder+File.separator+sendFolder+File.separator+listImages[i]+".zip");
					saveAs("Tiff", originalPath+File.separator+resultFolder+File.separator+sendFolder+File.separator+listImages[i]+".tif");
					print(listImages[i]+", "+class0+", "+nrois+", "+class1);
					
				}
			}else{
				print(listImages[i]+", "+class0+", 0, "+class0);
			}
		}
		
		//--- closing the image ---
		run("Close All");
    }
	
}

//--- closing the windows ---
setBatchMode(true);
run("Close All");

if(isOpen("Log"))
{
	selectWindow("Log");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	nameFile="checked_results_"+year+"_"+month+"_"+dayOfMonth+"_"+hour+"_"+minute+".csv";
	saveAs("Text", originalPath+File.separator+resultFolder+File.separator+sendFolder+File.separator+nameFile);
	run("Close");
}
if(isOpen("Results"))
{
	selectWindow("Results");
	run("Close");
}
if(isOpen("ROI Manager"))
{
	selectWindow("ROI Manager"); 
	run("Close");
}

open(originalPath+File.separator+resultFolder+File.separator+sendFolder+File.separator+nameFile);
resultsFile=nameFile;
Table.deleteColumn("model prediction");
Table.deleteColumn("num rois");
Table.update;
Table.rename(resultsFile, "Results");
saveAs("Results", originalPath+File.separator+resultFolder+File.separator+nameFile);


//--- removing the temporal files and folders ---
exec("sh","-c","rm-r "+outputPath);

print("The process is finished!");
print("");
print("You can find the results into: "+originalPath+File.separator+resultFolder+File.separator+nameFile);