

%% Profiles across signatures

doriver = 0; % 1 = river plot, 0 = polar plot

if ~doriver
    % Polar plot
    % ----------------------------------------------------------------
    printhdr('Cosine Similarity : First condition');
    
    create_figure('bucknerpluslabels');
    i = 1;
    [stats hh hhfill table_group multcomp_group] = image_similarity_plot(DATA_OBJ{i}, 'average', 'cosine_similarity', 'colors', DAT.colors(i), 'nofigure');
    drawnow, snapnow
    
    create_figure('npspluslabels');
    
    [stats hh hhfill table_group multcomp_group] = image_similarity_plot(DATA_OBJ{i}, 'average', 'cosine_similarity', 'colors', DAT.colors(i), 'nofigure', 'mapset', 'npsplus');
    drawnow, snapnow
    
    printhdr('Cosine Similarity : All conditions');
    
    k = length(DAT.conditions);
    
    create_figure('bucknerlab', 1, k);
    %[f1, axh] = create_figure('bucknerlab', 1, k);
    %axpos = {};
    %for i = 1:k, axpos{i} = get(axh(i), 'Position'); end
    
    for i = 1:k
        
        subplot(1, k, i);
        [stats hh hhfill table_group multcomp_group] = image_similarity_plot(DATA_OBJ{i}, 'average', 'cosine_similarity', 'colors', DAT.colors(i), 'nofigure');
        hh = findobj(gca, 'Type', 'Text'); delete(hh)
        title(DAT.conditions{i})
        camzoom(1.3)
        drawnow
    end
    
    %for i = 1:k, set(axh(i), 'Position', axpos{i}); end
    
    snapnow
    
    create_figure('npsplus', 1, k);
    
    for i = 1:k
        
        subplot(1, k, i);
        [stats hh hhfill table_group multcomp_group] = image_similarity_plot(DATA_OBJ{i}, 'average', 'cosine_similarity', 'colors', DAT.colors(i), 'nofigure', 'mapset', 'npsplus');
        hh = findobj(gca, 'Type', 'Text'); delete(hh)
        title(DAT.conditions{i})
        camzoom(1.3)
        drawnow
    end
    
    snapnow
    
else
    % Riverplot
    % ----------------------------------------------------------------
    printhdr('Cosine Similarity : All conditions');
    
    % Get mean data across subjects
    m = mean(DATA_OBJ{1});
    m.image_names = DAT.conditions{1};
    
    for i = 2:k
        
        m = cat(m, mean(DATA_OBJ{i}));
        m.image_names = strvcat(m.image_names, DAT.conditions{i});
        
    end
    
    [npsplus, netnames, imgnames] = load_image_set('npsplus');
    npsplus.image_names = netnames;
    
    riverplot(m, 'layer2', npsplus, 'pos', 'layer1colors', DAT.colors, 'layer2colors', seaborn_colors(4), 'thin');
    pause(2)
    
    drawnow, snapnow
    
end


%% Contrasts: All signatures
% ------------------------------------------------------------------------

if ~isfield(DAT, 'contrasts') || isempty(DAT.contrasts)
    % skip
    return
end

printhdr('Cosine Similarity : All contrasts');

k = size(DAT.contrasts, 1);

if ~doriver
    % Polar plot
    % ----------------------------------------------------------------
    
    create_figure('bucknerlab_contrasts', 1, k);
    
    for i = 1:k
        
        subplot(1, k, i);
        [stats hh hhfill table_group multcomp_group] = image_similarity_plot(DATA_OBJ_CON{i}, 'average', 'cosine_similarity', 'colors', DAT.contrastcolors(i), 'nofigure');
        hh = findobj(gca, 'Type', 'Text'); delete(hh)
        title(DAT.contrastnames{i})
        camzoom(1.3)
        drawnow
        
    end
    
    create_figure('npsplus_contrasts', 1, k);
    
    for i = 1:k
        
        subplot(1, k, i);
        [stats hh hhfill table_group multcomp_group] = image_similarity_plot(DATA_OBJ_CON{i}, 'average', 'cosine_similarity', 'colors', DAT.contrastcolors(i), 'nofigure', 'mapset', 'npsplus');
        hh = findobj(gca, 'Type', 'Text'); delete(hh)
        title(DAT.contrastnames{i})
        camzoom(1.3)
        drawnow
        
    end
    
else
    % River plot
    % ----------------------------------------------------------------
    % Get mean data across subjects
    m = mean(DATA_OBJ_CON{1});
    m.image_names = DAT.contrastnames{1};
    
    for i = 2:k
        
        m = cat(m, mean(DATA_OBJ_CON{i}));
        m.image_names = strvcat(m.image_names, DAT.contrastnames{i});
        
    end
    
    riverplot(m, 'layer2', npsplus, 'pos', 'layer1colors', DAT.colors, 'layer2colors', seaborn_colors(4), 'thin');
    
end

drawnow, snapnow