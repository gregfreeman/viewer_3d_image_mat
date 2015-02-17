[ img,meta ] =loadDicom3D( '/home/greg/Documents/shared/research/csprojects/data/mridata/P2_dcm' );
Viewer3D(img,meta)
h=ones(5,5,5)/(5^3);
mask=imfilter(img,h);
plot(squeeze(mask(150,150,:)))
mask=mask>50;
mask=imopen(mask,strel('disk',2));
mask=imclose(mask,strel('disk',20));

Viewer3D(mask,meta)