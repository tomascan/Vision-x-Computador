%Cerrar todas las figuras anteriores 
close all;
% Nombre del directorio que contiene las imágenes
name_dir = 'Imatges cucs/WormImages/';

% Nombre del archivo de verificación
check_file = 'Imatges cucs/WormData.csv';

% Llamada a la función de clasificación de imágenes
precision = gusanos(name_dir, check_file);

% Visualización de la precisión obtenida
fprintf('La precisión de la clasificación es del %.2f%%.\n', precision);