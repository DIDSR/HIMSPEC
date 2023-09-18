% WCC 9/18/2023
% Q: How to convert our data into Matlab Hyperspectral
%

%
% get all slide names in the 'input' folder
%
in = 'input';
af = dir(in);

%
% iterate all slides
%
for j = 3:numel(af)                    % skip . and ..

    sn = af(j).name;                   % get the slide name

    if strcmp(sn(1:13),'BiomaxOrgan10')            % if it starts with

        dn = sprintf('%s\\%s\\Transmittance',in,sn);     % construct the directory name

        for i = 2                                                 % read the first file to obtain the dimensions
            fn = sprintf('%s\\trans_mean_camera_%d.mat',dn,i);
            load(fn,'vv');
            sizex = size(vv,1);
            sizey = size(vv,2);
        end

        %
        % define ROI size, need to be < 100 MB for github
        %
        roi_x_half = 250;
        roi_y_half = 250;

        %
        % crop the center
        %
        range_x = round(sizex/2)-roi_x_half:round(sizex/2)+roi_x_half-1;
        range_y = round(sizey/2)-roi_y_half:round(sizey/2)+roi_y_half-1;

        %
        % save all wavelengths in a 3-dimensional cube
        % 
        cube3 = zeros(2*roi_y_half,2*roi_x_half,40);

        for i = 2:40
            fn = sprintf('%s\\trans_mean_camera_%d.mat',dn,i);
            load(fn,'vv');
            cube3(:,:,i) = vv(range_y,range_x);
        end

        %
        % convert to Matlab Hypercube; remember to install the Image Processing Toolbox™ Hyperspectral Imaging Library
        % https://www.mathworks.com/help/images/ref/hypercube.html#d126e342432
        % 
        hc = hypercube(cube3,[390:10:780]);

        %
        % save the results in the 'hypercube' folder
        %
        outfn = sprintf('hypercube\\%s.mat',sn);       
        save(outfn,'hc')
    end

end