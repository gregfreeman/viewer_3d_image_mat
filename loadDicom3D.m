function [ img,meta ] = loadDicom3D( folder )
% loadDicom3D( folder )
% loads a dicom 3D image from .mag files in a folder
%

d = dir(fullfile(folder,'*.mag'));
topimage = dicomread(fullfile(folder,d(1).name));
metadata = dicominfo(fullfile(folder,d(1).name));

[group1, element1] = dicomlookup('PixelSpacing');
[group2, element2] = dicomlookup('SliceThickness');
resolution = metadata.(dicomlookup(group1, element1));
meta.xthickness = resolution(1); 
meta.ythickness = resolution(2);
meta.zthickness = metadata.(dicomlookup(group2, element2));

img = zeros(size(topimage,1),size(topimage,2),size(d,1));
img(:,:,1) = topimage;

for i = 2:size(d,1)
   img(:,:,i) = dicomread(fullfile(folder,d(i).name));
end


end 
