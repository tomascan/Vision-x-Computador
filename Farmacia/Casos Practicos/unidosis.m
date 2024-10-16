close all;

RGB = imread('Unidosis/Unidosis2.PNG');

gris=RGB(:,:,3);
figure
imshow(RGB);
title('Imagen a escala de grises');

BW = edge(gris,'sobel',0.05);
figure
imshow (BW);
title('Imagen gris bordes');

mascara=ones(5,5);
bwmask=imfilter(BW,mascara);
figure
imshow(bwmask);
title('Imagen bordes despues mascara');


BW2 = imfill(bwmask,'holes')
figure
imshow(BW2);
title('Imagen rellenada');

BW2 = imopen(BW2,strel('disk',10));
figure
imshow(BW2);
title('Imagen rellenada filtrada'); 

background=BW2;
cc = bwconncomp(background, 8);
cc.NumObjects;

stats = regionprops(cc, 'all');
areas = [stats.Area];
disp('Elementos conectados')
disp(cc.NumObjects)


% Caso Generalizado (solapamiento)
stats = regionprops(cc, 'all');
areas = [stats.Area];

agrupmayor=max(areas)/min(areas);
figure, hist(areas,agrupmayor);
u=hist(areas,agrupmayor);


h=length(u);
capsulas=0;
for w=1:h
 capsulas=capsulas+w*u(w);
end

msgbox(['Número total de cápsulas: ' num2str(capsulas)]);