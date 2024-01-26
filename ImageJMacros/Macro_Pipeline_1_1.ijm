/*
 * PSYCOTRIP - Universidad de La Rioja
 * 
 * GOAL: segment the cells of a citology image and get an image of 64x64 pixels, where the roi is centerd
 *
 * INPUT: 	select the folder with the tif-images to analyze  
 * 			
 * OUTPUT: 	each patch of each image is saved into the folder with the name of the image, also the zip-file with the rois in the whole image
 * 		The model predict if the image is malign or not malign
 * 
 * Description:	
 * 
 *
 * Options: 
 * 			change the name of the output folder
 * 			batch mode (true/false)
 * 			change the algorithm to the threshold
 * 			change the default values for:
 * 				mean of intensity of blue channel
 * 				minimum and maximum size of a roi
 * 				minimum and maximum value of circularity of a roi
 * 				width and height of the patch
 * 
 * Notes:
 * 		this macro is a colaboration with ZgZ
 *
 * Last Update October 2022
*/

//VARIABLES
outputFolder="--Output_Segmentation"; //name of the output folder
processedFolder="--processed";
batchMode=true; //to enable the background process //it is true, the macro does not work.
threshold="RenyiEntropy";
meanthBlue=200;
minSize=8;
maxSize="Infinity";
minCirc=0;
maxCirc=1.0;
wcrop=64;
hcrop=64;

//PROCESS 
print("\\Clear");
setForegroundColor(255, 255, 255);
timeO=getTime();
run("Bio-Formats Macro Extensions");

dirI = getDirectory("Choose folder with I files ");

setBatchMode(batchMode);

dirIparent = File.getParent(dirI);
dirIname = File.getName(dirI);
dirOutI = dirIparent+File.separator+dirIname+outputFolder;
if (File.exists(dirOutI)==false) {
     File.makeDirectory(dirOutI); // new output folder
}

dirOutP = dirIparent+File.separator+dirIname+processedFolder;
if (File.exists(dirOutP)==false) {
     File.makeDirectory(dirOutP); // new processed folder
}

dirOutModel=dirOutI+File.separator+"model";
if (File.exists(dirOutModel)==false) {
     File.makeDirectory(dirOutModel); // new output folder
}
dirOutTrain=dirOutModel+File.separator+"train";
if (File.exists(dirOutTrain)==false) {
     File.makeDirectory(dirOutTrain); // new output folder
}
dirOutValid=dirOutModel+File.separator+"valid";
if (File.exists(dirOutValid)==false) {
     File.makeDirectory(dirOutValid); // new output folder
}
dirOutImgS3=dirOutI+File.separator+"imgS3_rois";
if (File.exists(dirOutImgS3)==false) {
     File.makeDirectory(dirOutImgS3); // new output folder
}
//create a stack
newImage("blackstack", "RGB black", wcrop, hcrop, 2);
saveAs("Tiff", dirOutI+File.separator+"blackstack.tif");
close();	  

//Starting
print("Starting...");
list = getFileList(dirI);
print("number of files in the folder: "+list.length);
for (i=0; i<list.length; i++) //list.length
{
     pathI=dirI+list[i];
     print(pathI);
     //only tif-files
     indexExt= lastIndexOf(list[i], "."); //indexOf(string, substring) Returns the index within string of the last occurrence of substring
     extension= substring(list[i], indexExt);
     if(extension==".tif"){
     	  timeOopen=getTime();
          run("Bio-Formats", "open=pathI autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+3);
          timeL=getTime();//Returns the current time in milliseconds.
		  time=(timeL-timeOopen)/1000;
		  print("Open image time: "+time+"sec");
		  timeOopen=getTime();
          title=getTitle();
          /*dirOutImage = dirOutI+File.separator+title;
          if (File.exists(dirOutImage)==false) {
               File.makeDirectory(dirOutImage); // new output folder
          }*/
          
          auxTitle=split(title, "C");
          name=auxTitle[0];
          print(title);
          run("Stack to RGB");
          saveAs("Tiff", dirOutImgS3+File.separator+name+".tif"); //Image Serie 3
          titRGB=getTitle();
          selectImage(title);
          close();
          run("Colour Deconvolution", "vectors=[H&E DAB]");
          selectWindow(titRGB+"-(Colour_2)");
          close();
          selectWindow(titRGB+"-(Colour_1)");

          selectWindow(titRGB+"-(Colour_3)");
          setAutoThreshold(threshold);
          setOption("BlackBackground", false);
          run("Convert to Mask");
          rename("Mask");
          //selecting cells and clusters of cells
          run("Analyze Particles...", "size="+minSize+"-"+maxSize+" circularity="+minCirc+"-"+maxCirc+" show=Masks add");
          roiManager("save", dirOutImgS3+File.separator+name+"_allrois.zip");
          //roiManager("reset");
          //run("Find Maxima...", "prominence=10 light output=List");
          nRois=roiManager("count");
          rois2Delete=newArray(nRois);
          k=0;
          timeL=getTime();//Returns the current time in milliseconds.
		  time=(timeL-timeOopen)/1000;
		  print("analyze particles: "+time+"sec");
		  print(nRois+" rois");
		  timeOopen=getTime();
		  selectWindow("Colour Deconvolution");
		  close();
		  selectWindow("Mask");
		  close();
		  open(dirOutI+File.separator+"blackstack.tif");
		  //create the crops from the rois
		   timeOoopen=getTime();
          for(j=0;j<nRois;j++){
               selectWindow(titRGB+"-(Colour_1)");
               roiManager("select", j);
               getStatistics(area, mean, min, max, std, histogram);
			   if(j%100==0){
			   	print("Processed " + j +"/"+nRois);	
			   }
				
               if(mean<meanthBlue){
                       
                    selectWindow(titRGB);
                    roiManager("select", j);
                    run("Duplicate...", "duplicate");
                    roiName="roi_"+Roi.getName;
                    rename(roiName);
                    run("Select None");
                    height=getHeight();
                    width=getWidth();
                    xc=round(width/2)+1;
                    yc=round(height/2)+1;
                    if(width<height){
                         run("Specify...", "width="+width+" height="+width+" x="+xc+" y="+yc+" centered");
                         run("Crop");
                    }
                    if(height<width)
                    {
                         run("Specify...", "width="+height+" height="+height+" x="+xc+" y="+yc+" centered");
                         run("Crop");
                    }
                    run("Select None");
                    selectWindow(roiName);
                    run("Scale...", "x=- y=- width="+wcrop+" height="+hcrop+" interpolation=Bilinear average create");
                    selectWindow(roiName);
                    close();
                    selectWindow(roiName+"-1");
                    rename(roiName);
                    setMetadata("Label", roiName);
                    //saveAs("Tiff", dirOutValid+File.separator+name+"_"+roiName+".tif");
					//setBatchMode(false);      
					
					//waitForUser("");
					//run("Concatenate...", "open image1=blackstack-1.tif image2=roi_0002-0049-1 image3=[-- None --]");
                    run("Concatenate...", "open image1=blackstack.tif image2="+roiName);
                    rename("blackstack.tif");

                    
               }
               else{//save the rois to delete in the next step
                    rois2Delete[k]=j;
                    k++;
               }
          }
		  //remove the first two slices of the stack and save it
		  selectWindow("blackstack.tif");
		  setSlice(1);
		  run("Delete Slice");
		  setSlice(1);
		  run("Delete Slice");
		  saveAs("Tiff", dirOutValid+File.separator+name+"_rois.tif");
			timeL=getTime();//Returns the current time in milliseconds.
		  time=(timeL-timeOoopen)/1000;
		  print("time del for: "+time);
          //delete the rois no selected because the blue intensity is low
          for(l=k-1;l>-1;l--)
          {
               roiManager("select", rois2Delete[l]);
               roiManager("delete");
          }
          roiManager("save", dirOutImgS3+File.separator+name+"_woRedCells.zip");
          timeL=getTime();//Returns the current time in milliseconds.
		  time=(timeL-timeOopen)/1000;
		  print("save rois and image: "+time+"sec");
     }
     run("Close All");
     run("Clear Results");
}
//copy a only image into the train-folder
list = getFileList(dirOutValid);
listFiles = Array.copy(list);
pathImage=dirOutValid+File.separator+list[0];
pathImgCopy=dirOutTrain+File.separator+list[0];
File.copy(pathImage,pathImgCopy);

//closing all
if(isOpen("Results")){
     selectWindow("Results");
     run("Close");
}
if(isOpen("Roi Manager")){
     selectWindow("Roi Manager");
     run("Close");
}
timeL=getTime();//Returns the current time in milliseconds.
time=(timeL-timeO)/1000;
print("total time: "+time+"sec");



for(i=0;i<listFiles.length;i++){
	
	//step 1.2: obtaining the crops from the stacks
	print("obtaining the crops-images...");
	timeO=getTime();
	exec("sh", "-c", "python /home/jonathan/hd/Fiji/Bruno/test2.py " + dirOutI + "/model/valid/ \'" +listFiles[i] + "\'");
	timeL=getTime();//Returns the current time in milliseconds.
	time=(timeL-timeO)/1000;
	print("total time: "+time+"sec");
	
	//step 1.3: removing stack
	print("removing stack...");
	timeO=getTime();
	exec("sh", "-c", "python /home/jonathan/hd/Fiji/Bruno/test_remove.py " + dirOutI + "/model/valid/ \'" +listFiles[i] + "\'");
	timeL=getTime();//Returns the current time in milliseconds.
	time=(timeL-timeO)/1000;
	print("total time: "+time+"sec");
    
	exec("sh", "-c", "mv " + dirIparent+File.separator+dirIname + "/ \'" +listFiles[i] + "\' " + dirOutP + "/ \'" +listFiles[i] + "\' ");    
    
}

//step 2: obtaining the predictions

print("applying the model...");
timeO=getTime();
exec("sh", "-c", "anomaly-detection "+dirOutModel);
timeL=getTime();//Returns the current time in milliseconds.
time=(timeL-timeO)/1000;
print("total time: "+time+"sec");
print("Done!");
