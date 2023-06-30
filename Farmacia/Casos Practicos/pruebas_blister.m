% Cargar imagen
img = imread('Capell_pastilles/pastilles7.jpg');

% Convertir a escala de grises
gray = rgb2gray(img);

% Aplicar filtro de mediana para reducir ruido
gray = medfilt2(gray, [5,5]);

% Obtener máscara del blister
bin = imbinarize(gray, 'adaptive', 'Sensitivity', 0.55);
bin_clean = bwareaopen(bin, 5000);
bin_blister = imfill(bin_clean, 'holes');
bin_edges = edge(bin_blister, 'Canny');

% Suavizar los bordes utilizando la operación morfológica de cierre
se = strel('disk', 13);
se1 = strel('disk', 13);
edges_dilate = imdilate(bin_edges, se);
edges_closed = imerode(edges_dilate, se1);
% Mostrar la imagen con los bordes suavizados
figure
imshow(edges_closed);

% Aislar pastillas mediante mascaras  
labels = bwlabel(edges_closed);
prop = regionprops(labels, 'Area');

areas = [prop.Area];
[~, index] = sort(areas, 'descend');
edge_blister = index(1);
mask_blister = ismember(labels, edge_blister);
mask_pills = edges_closed & ~mask_blister;


filled_pills = imfill(mask_pills, 'holes');
pre_pills = filled_pills - mask_pills;

se1 = strel('diamond', 4);
pre_pills = imerode(pre_pills, se1);

figure
imshow(pre_pills);
% Obtener datos de las pastillas 
[pills, numPills] = bwlabel(pre_pills);

props=regionprops(pills, 'Area', 'MajorAxisLength', 'MinorAxisLength');
tabla = struct2table(props);
division = tabla{:, 'MajorAxisLength'} ./ tabla{:, 'MinorAxisLength'};
tabla.Division = division;
disp(tabla(:, {'Area','MajorAxisLength', 'MinorAxisLength', 'Division'}));

% Separar los objetos según su forma y tamaño
correcta = 0;
defecto = 0;
if numel(props) < 10
    defecto = 10 - numel(props);
end
for i = 1:numel(props)
    if (props(i).MajorAxisLength/props(i).MinorAxisLength < 2)
        % Pastilla comprometida 
        defecto = defecto + 1;
        pills(pills == i) = 255;
    else
        correcta = correcta + 1;
        pills(pills == i) = 55;
    end
end


% Mostrar la imagen resultante
RGB = label2rgb(pills, 'jet', 'k');
figure
subplot(1,2,1);
title('Imagen Original'); 
imshow(img);
subplot(1,2,2);
imshow(RGB);


