function precision=gusanos(name_dir, check_file)
directorio=dir(name_dir);
checker=readtable(check_file);
correct_img=0;
total_img=0;

for num_image=3:length(directorio)
    %Cargar Imagen en escala de grises
    img=imread(append(name_dir, directorio(num_image).name));
    
    %Reajustar la imagen y recortar background
    resized = imresize(img, 1.5);
    
    [h, w] = size(img);
    w_crop = round(w * 0.2);
    h_crop = round(h * 0.05);
    cropped = resized(h_crop+80:end-h_crop, w_crop:end-w_crop);
    
    %------------------------------------------
    % Preprocesamiento
    
    contrast = imadjust(cropped, [],[], 1.5);
    filtered = medfilt2(contrast, [5 5]);
    bin = ~imbinarize(filtered, 'adaptive', 'Sensitivity', 1);
    clean = bwareaopen(bin, 200);
    
    %------------------------------
    % Aislar gusanos mediante mascaras
    
    [labels] = bwlabel(clean);
    prop = regionprops(labels, 'Area');
    
    areas = [prop.Area];
    [~, index] = sort(areas, 'descend');
    edge_index = index(1);
    mask_lente = ismember(labels, edge_index);
    mask_cucs = clean & ~mask_lente;
    
    %-------------------------------
    %Deteccion de bordes y rellenado
    edges = edge(mask_cucs, 'Canny');
    se = strel('disk', 2);
    edges_open = imdilate(edges, se);
    edges_filled = imfill(edges_open, 'holes');
    pre_worms = edges_filled - edges_open;
    worms = bwareaopen(pre_worms, 200);
    
    %-----------------------------------
    %Eliminar posibles circulos generados
    [worms_label, num_worms] = bwlabel(worms);
    worms_props = regionprops(worms_label, 'Area', 'Perimeter');
    % Eliminar objetos con circularidad cercana a 1
    for i = 1:num_worms
        circularity = 4*pi*worms_props(i).Area/worms_props(i).Perimeter^2;
        if abs(circularity - 1) < 0.3
            worms(worms_label == i) = 0;
        end
    end
    
    
    %------------------------------
    % TRATAR GUSANOS UNIDOS
    
    % Crear máscaras vacías para los gusanos separados y unidos
    joined_gusanos = false(size(worms));
    small_gusanos = false(size(worms));

    [gusanos_label, num_gusanos] = bwlabel(worms);
    gusanos_props = regionprops(gusanos_label, 'Area');
    % Procesar posibles gusanos unidos
    for i = 1:num_gusanos
        if gusanos_props(i).Area > 1700
            % Erosion para separar los objetos
            se = strel('disk', 3);
            gusano = gusanos_label == i;
            gusano = imerode(gusano, se);
            joined_gusanos = joined_gusanos | gusano;
        elseif gusanos_props(i).Area > 1200
            se = strel('square', 2);
            gusano = gusanos_label == i;
            gusano = imerode(gusano, se);            
            joined_gusanos = joined_gusanos | gusano;
        end
    end
    %Añadir gusanos pequeños
    for i = 1:num_gusanos
        if gusanos_props(i).Area < 1200
            gusano = gusanos_label == i;
            small_gusanos = small_gusanos | gusano;
        end
    end
    % Unir las dos máscaras
    gusanos = joined_gusanos | small_gusanos;
    gusanos = bwareaopen(gusanos, 100);
    % -------------------------------------------------
    %CLASIFICAR SEGÚN LA FORMA
    [cucs_label, num_cucs] = bwlabel(gusanos);
    cucs_props = regionprops(cucs_label, 'Area','MajorAxisLength','MinorAxisLength');
    tabla = struct2table(cucs_props);
    relacion = tabla{:, 'MajorAxisLength'} ./ tabla{:, 'MinorAxisLength'};
    tabla.Relacion = relacion;
    %disp(tabla(:, {'Area','MajorAxisLength', 'MinorAxisLength', 'Relacion'}));
    
    num_vivos = 0;
    num_muertos = 0;
    for i = 1:num_cucs
        
        if (cucs_props(i).MajorAxisLength/cucs_props(i).MinorAxisLength < 10)
            % Objeto curvilíneo (probablemente vivo)
            num_vivos = num_vivos + 1;
            cucs_label(cucs_label == i) = 125;
        else
            % Objeto rectilíneo (probablemente muerto)
            num_muertos = num_muertos + 1;
            cucs_label(cucs_label == i) = 255;
        end
    end
    
    % -------------------------------------
    % Mostrar la imagen resultante
    RGB = label2rgb(cucs_label, 'jet', 'k');
    figure
    subplot(1,2,1);
    imshow(cropped);
    title(['Imagen Original: ', num2str(num_image-2)]);
    subplot(1,2,2);
    imshow(RGB);
    title(['Objetos encontrados: ', num2str(num_vivos), ' vivos y ', num2str(num_muertos), ' muertos']);
    
    %COMPARAR CON EL FICHERO DE VALIDACION
    if (num_vivos > num_muertos)                                                
        classify='alive';                                                   
    else
        classify='dead';
    end
    
    if (strcmp(classify, checker{num_image-2, "Status"}))
        correct_img=correct_img+1;
    else
        fprintf('Fallo en:%d', num_image);
    end
    total_img=total_img+1;                                             
end
precision=(correct_img/total_img)*100; 
end