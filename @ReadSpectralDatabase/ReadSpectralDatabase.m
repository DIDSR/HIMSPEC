classdef ReadSpectralDatabase < handle
    %ReadSpectralDatabase Image class for hyperspectral imaging microscope measurements
    % Load the transmittance data (mean value and standard deviation) and
    % computes the CIEXYZ, CIELAB coordinates and their covariance
    % matrices, computes the sRGB coordinates and tiff image
    
    %% Properties
    % Sample
    properties
        biomax_path             % Path to BiomaxOrgan10 data
        sample                  % Name of BiomaxOrgan10 sample
    end
    % Images properties
    properties
        sizex                   % Number of columns in the image
        sizey                   % Number of rows in the imag
        lambda = 390:10:770     % 390 nm to 770 nm in steps of 10 nm
        sig_m                   % Mean values of the transmittance
        sig_s                   % Standard deviation values of the transmittance
    end
    
    % CIE coordinates + rgb
    properties
        ls                      % Illuminant spectrum
        cmf                     % Tri-stimulus functions
        XYZ                     % CIE1931 XYZ coordinates
        XYZ0                    % CIE1931 XYZ coordinates for the white point (T = 100%)
        CovXYZ                  % Covariance matrices on the CIE1931 XYZ coordinates
        LAB                     % CIE1976 Lab coordinates
        CovLAB                  % Covariance matrices on the CIE1976 Lab coordinates
        Y0 = 100                % Normalization factor
        rgb                     % sRGB coordinates
    end
        
    %% Methods
    methods
        
        %% Constructor
        function obj = ReadSpectralDatabase(b_p, n)
            %ReadSpectralDatabase(b_p, n) 
            % Set biomax path and sample name, load the data
            
            % Set path to data
            obj.biomax_path = b_p; 
            
            % Set name of the sample
            obj.sample = n;

            % Load the spectral data
            obj.load_data;
        end
        
        %% Set functions
        function set_ls(obj, ls)
            %set_ls
            % Pass the standard illuminant to the class object
            obj.ls = ls;
        end
        
        %% Load data
        function obj = load_data(obj)
            %load_data
            % Loads the transmittance values from the data files
            % Set the transmittance mean values (sig_m), the transmittance
            % standard deviation values (sig_s) and the image size (sizex,
            % sizey). pass these to the class object
            
            % Load sample files
            path = [obj.biomax_path '\input\' obj.sample '\Transmittance\'];
            
            % Stack the 39 files into one file, one or transmittance mean values and
            % one for transmittance standard deviations
            if(~(isfile([path 'trans_mean_camera.mat']) && isfile([path 'trans_std_camera.mat'])))
                obj.stacker(path);
            end
           
            % Mean values of the transmittance
            dataName = [path 'trans_mean_camera'];
            temp = load(dataName);
            obj.sig_m = temp.trans_array_m;
            
            % Image size
            obj.sizex = temp.sizex;
            obj.sizey = temp.sizey;
            
            % Standard deviation of the transmittance
            dataName = [path 'trans_std_camera'];
            temp = load(dataName);
            obj.sig_s = temp.trans_array_s;
        end
        
        function obj = stacker(obj, path)
            %stacker
            % Stacks the transmittance data for each wavelength
            % into a 39 x (sizex x sizey) dataset
            
            outputName = {'trans_mean_camera', 'trans_std_camera'};
            sizeLambda = size(obj.lambda, 2);
            
            % Load sizex and size y for size of out array
            loadName = insertBefore([path outputName{1} '.mat'], '.mat', '_2');
            load(loadName, 'sizex', 'sizey');

            for i=1:2
                out = zeros(sizeLambda, sizey, sizex); 
                for wl = 1:sizeLambda
                    loadName = insertBefore([path outputName{i} '.mat'], '.mat', ['_' int2str(wl+1)]); % trans_xx_camera_2 = 390 nm, trans_xx_camera_40 = 770 nm
                    temp = load(loadName);
                    out(wl, :, :) = temp.vv;
                end
                
                switch i
                    case 1
                        disp('Stack transmittance mean values into one file...')
                        trans_array_m = reshape(out, sizeLambda, sizey * sizex); 
                        save([path 'trans_mean_camera.mat'], 'trans_array_m', 'sizey', 'sizex', '-v7.3');
                    case 2
                        disp('Stack transmittance standard devation values into one file...')
                        trans_array_s = reshape(out, sizeLambda, sizey * sizex);
                        save([path 'trans_std_camera.mat'], 'trans_array_s', 'sizey', 'sizex', '-v7.3');
                end
            end
        end
        
        %% CIE coordinates and covariance matrices 
        function col_match_f(obj)
            %col_match_f
            % Color matching functions xbar, ybar, zbar from 390 nm to 770
            % nm in steps of 10 nm
            obj.cmf = [
                390.0 0.004243 0.000120 0.020050;
                400.0 0.014310 0.000396 0.067850;
                410.0 0.043510 0.001210 0.207400;
                420.0 0.134380 0.004000 0.645600;
                430.0 0.283900 0.011600 1.385600;
                440.0 0.348280 0.023000 1.747060;
                450.0 0.336200 0.038000 1.772110;
                460.0 0.290800 0.060000 1.669200;
                470.0 0.195360 0.090980 1.287640;
                480.0 0.095640 0.139020 0.812950;
                490.0 0.032010 0.208020 0.465180;
                500.0 0.004900 0.323000 0.272000;
                510.0 0.009300 0.503000 0.158200;
                520.0 0.063270 0.710000 0.078250;
                530.0 0.165500 0.862000 0.042160;
                540.0 0.290400 0.954000 0.020300;
                550.0 0.433450 0.994950 0.008750;
                560.0 0.594500 0.995000 0.003900;
                570.0 0.762100 0.952000 0.002100;
                580.0 0.916300 0.870000 0.001650;
                590.0 1.026300 0.757000 0.001100;
                600.0 1.062200 0.631000 0.000800;
                610.0 1.002600 0.503000 0.000340;
                620.0 0.854450 0.381000 0.000190;
                630.0 0.642400 0.265000 0.000050;
                640.0 0.447900 0.175000 0.000020;
                650.0 0.283500 0.107000 0.000000;
                660.0 0.164900 0.061000 0.000000;
                670.0 0.087400 0.032000 0.000000;
                680.0 0.046770 0.017000 0.000000;
                690.0 0.022700 0.008210 0.000000;
                700.0 0.011359 0.004102 0.000000;
                710.0 0.005790 0.002091 0.000000;
                720.0 0.002899 0.001047 0.000000;
                730.0 0.001440 0.000520 0.000000;
                740.0 0.000690 0.000249 0.000000;
                750.0 0.000332 0.000120 0.000000;
                760.0 0.000166 0.000060 0.000000;
                770.0 0.000083 0.000030 0.000000;
                ];
        end
        
        function spd2XYZ(obj, ls)
            %spd2XYZ
            % Transmittance measurements to CIEXYZ tri-stimulus values, T -> CIEXYZ
            
            % Color matching functions
            obj.col_match_f;
            
            input_n = size(obj.sig_m, 2); % Number of pixel in image
            x_bar = repmat(obj.cmf(: ,2), 1, input_n);
            y_bar = repmat(obj.cmf(: ,3), 1, input_n);
            z_bar = repmat(obj.cmf(: ,4), 1, input_n);
            
            % XYZ coordinates
            k = 100/sum(obj.cmf(: ,3).*ls(:, 1)); % Normalization factor
            sig_m_ls = obj.sig_m .* ls;
            
            X = k * sum(sig_m_ls .* x_bar);
            Y = k * sum(sig_m_ls .* y_bar);
            Z = k * sum(sig_m_ls .* z_bar);
            
            obj.XYZ = [X' Y' Z'];
        end
                
        function stddev_spd2CovXYZ(obj, ls)
            %stddev_spd2CovXYZ
            % Standard deviation on the transmittance measurements to covariance matrix on XYZ, stddev(T) -> CovXYZ
            
            % XYZ Uncertainties
            input_n = size(obj.sig_s, 2);
            x_bar = repmat(obj.cmf(: ,2),1,input_n);
            y_bar = repmat(obj.cmf(: ,3),1,input_n);
            z_bar = repmat(obj.cmf(: ,4),1,input_n);
            
            k = 100/sum(obj.cmf(: ,3).*ls(:, 1)); % Normalization factor
              
            if ~isempty(obj.sig_s)
                obj.CovXYZ =  zeros(3, 3, input_n);
                
                % Jacobian elements accross all coordinates
                J_x = k * ls .* x_bar;
                J_y = k * ls .* y_bar;
                J_z = k * ls .* z_bar;
                
                % CovX x J across all pixels
                V_x = (obj.sig_s.^2) .* J_x;
                V_y = (obj.sig_s.^2) .* J_y;
                V_z = (obj.sig_s.^2) .* J_z;
                
                % First line of CovXYZ
                obj.CovXYZ(1, 1,:) =  sum(J_x .* V_x);
                obj.CovXYZ(1, 2,:) =  sum(J_x .* V_y);
                obj.CovXYZ(1, 3,:) =  sum(J_x .* V_z);
                
                % Second line of CovXYZ
                obj.CovXYZ(2, 1,:) =  sum(J_y .* V_x);
                obj.CovXYZ(2, 2,:) =  sum(J_y .* V_y);
                obj.CovXYZ(2, 3,:) =  sum(J_y .* V_z);
                
                % Third line of CovXYZ
                obj.CovXYZ(3, 1,:) =  sum(J_z .* V_x);
                obj.CovXYZ(3, 2,:) =  sum(J_z .* V_y);
                obj.CovXYZ(3, 3,:) =  sum(J_z .* V_z);
            else
                obj.CovXYZ = [];
            end
        end
        
        function XYZ_white(obj)
            %XYZ_white
            % XYZ coordinates of reference white
            
            % Tristimulus spectral functions
            x_bar = obj.cmf(: ,2);
            y_bar = obj.cmf(: ,3);
            z_bar = obj.cmf(: ,4);
                        
            k = 100/sum(obj.cmf(: ,3).*obj.ls(:, 1)); % Normalization factor
            
            sig_m_ls = obj.ls;
            X = k * sum(sig_m_ls .* x_bar);
            Y = k * sum(sig_m_ls .* y_bar);
            Z = k * sum(sig_m_ls .* z_bar);
            
            obj.XYZ0 = [X' Y' Z'];
                        
        end
        
        function XYZ2lab(obj)
            %XYZ2lab
            % CIEXYZ to CIELAB, XYZ -> LAB
            
            % XYZ is k-by-3
            % XYZ_white is 1-by-3
            k = size(obj.XYZ,1);
            obj.XYZ_white; % Create the XYZ0 values of the white by calling XYZ_white(obj)
            XYZn = repmat(obj.XYZ0,k,1);
            XYZ_over_XYZn = obj.XYZ./XYZn;
            
            % CIELab values
            lstar = 116 * helpf(XYZ_over_XYZn(:,2)) - 16;
            astar = 500 * (helpf(XYZ_over_XYZn(:,1)) - helpf(XYZ_over_XYZn(:,2)));
            bstar = 200 * (helpf(XYZ_over_XYZn(:,2)) - helpf(XYZ_over_XYZn(:,3)));
            
            obj.LAB = [lstar astar bstar];
            
            return
            
            % Domain function
            function ys = helpf (t)
                % conditional mask
                t_greater = (t > power(6/29,3));
                
                % conditional assignment
                t(t_greater) = t(t_greater) .^ (1/3);
                t(~t_greater) = t(~t_greater) * (((29/6)^2)/3) + 4/29;
                
                ys = t;
            end
            
        end
       
        function CovXYZ2Covlab(obj)
            %CovXYZ2Covlab
            % Covariance on YXZ to covariance on LAB, CovXYZ -> CovLAB
            
            % XYZ is k-by-3
            % XYZ_white is 1-by-3
            k = size(obj.XYZ,1);
            obj.XYZ_white; % Create the XYZ0 values of the white by calling XYZ_white(obj)
            XYZn = repmat(obj.XYZ0,k,1);
            XYZ_over_XYZn = obj.XYZ./XYZn;
     
            if ~isempty(obj.CovXYZ)
                % Covariance matrix of CIELab values
                obj.CovLAB =  zeros(3, 3, k);
                
                % Transpose of Jacobian
                J_x_t = [zeros(k, 1)'; (116 ./ XYZn(:, 2) .* helpf_p (XYZ_over_XYZn(:,2)))';...
                    zeros(k, 1)'];
                J_y_t = [(500 ./ XYZn(:, 1) .* helpf_p (XYZ_over_XYZn(:, 1)))'; ...
                    (-500 ./ XYZn(:, 2) .* helpf_p (XYZ_over_XYZn(:, 2)))'; zeros(k, 1)'];
                J_z_t = [zeros(k, 1)'; (200 ./ XYZn(:, 2) .* helpf_p (XYZ_over_XYZn(:, 2)))';...
                    (-200 ./ XYZn(:, 3) .* helpf_p (XYZ_over_XYZn(:, 3)))'];
                
                % First product, CovXYZ * J'
                CovXYZ_x = reshape(obj.CovXYZ(1, :, :), 3, k); % First row of CovXYZ
                CovXYZ_Jt_11 = sum(CovXYZ_x .* J_x_t);
                CovXYZ_Jt_12 = sum(CovXYZ_x .* J_y_t);
                CovXYZ_Jt_13 = sum(CovXYZ_x .* J_z_t);
                
                CovXYZ_y = reshape(obj.CovXYZ(2, :, :), 3, k); % Second row of CovXYZ
                CovXYZ_Jt_21 = sum(CovXYZ_y .* J_x_t);
                CovXYZ_Jt_22 = sum(CovXYZ_y .* J_y_t);
                CovXYZ_Jt_23 = sum(CovXYZ_y .* J_z_t);
                
                CovXYZ_z = reshape(obj.CovXYZ(3, :, :), 3, k); % Third row of CovXYZ
                CovXYZ_Jt_31 = sum(CovXYZ_z .* J_x_t);
                CovXYZ_Jt_32 = sum(CovXYZ_z .* J_y_t);
                CovXYZ_Jt_33 = sum(CovXYZ_z .* J_z_t);
                
                CovXYZ_Jt = permute(cat(3, [CovXYZ_Jt_11' CovXYZ_Jt_12' CovXYZ_Jt_13'], ...
                    [CovXYZ_Jt_21', CovXYZ_Jt_22', CovXYZ_Jt_23'], [CovXYZ_Jt_31' CovXYZ_Jt_32' CovXYZ_Jt_33']), [3 2 1]); % Permutation of array dimensions
                
                % CovLAB
                % First col
                CovXYZ_Jt_col1 = reshape(CovXYZ_Jt(:, 1, :), 3, k);
                obj.CovLAB(1, 1, :) = sum(J_x_t .* CovXYZ_Jt_col1);
                obj.CovLAB(2, 1, :) = sum(J_y_t .* CovXYZ_Jt_col1);
                obj.CovLAB(3, 1, :) = sum(J_z_t .* CovXYZ_Jt_col1);
                
                % Second col
                CovXYZ_Jt_col2 = reshape(CovXYZ_Jt(:, 2, :), 3, k);
                obj.CovLAB(1, 2, :) = sum(J_x_t .* CovXYZ_Jt_col2);
                obj.CovLAB(2, 2, :) = sum(J_y_t .* CovXYZ_Jt_col2);
                obj.CovLAB(3, 2, :) = sum(J_z_t .* CovXYZ_Jt_col2);
                
                % Third col
                CovXYZ_Jt_col3 = reshape(CovXYZ_Jt(:, 3, :), 3, k);
                obj.CovLAB(1, 3, :) = sum(J_x_t .* CovXYZ_Jt_col3);
                obj.CovLAB(2, 3, :) = sum(J_y_t .* CovXYZ_Jt_col3);
                obj.CovLAB(3, 3, :) = sum(J_z_t .* CovXYZ_Jt_col3);
                
            else
                obj.CovLAB = [];
            end
            
            return
          
            % Derivative of domain function
            function ys = helpf_p (t)
                % conditional mask
                t_greater = (t > power(6/29,3));
                
                % conditional assignment
                t(t_greater) = 1 ./ (3 *(t(t_greater) .^ (2/3) ) );
                t(~t_greater) = ((29/6)^2)/3;
                
                ys = t;
            end
        end
        
        function xy = XYZ2xy(obj)
            %XYZ2xy
            % Converts the CIEXZY coordinates into the chromaticity values
            % Outputs the chromaticity as a [sizex * sizey, 2] table
            
            xy = zeros(size(obj.sig_m, 2) , 2);
            xy(:, 1) = obj.XYZ(:, 1)./sum(obj.XYZ, 2);
            xy(:, 2) = obj.XYZ(:, 2)./sum(obj.XYZ, 2);
        end
        
        function trimTransmittance(obj, trim)
            %trimTransmittance
            % Set the max input T to 1 and proportionaly scales the uncertainty (multiplicative noise assumption)
            switch trim
                case 'y'
                    tmp = min(obj.sig_m, 1); %  Sets max T to 1
                    diff = tmp - obj.sig_m;
                    mask_trim = diff ~=0;
                    
                    if ~isempty(obj.sig_s)
                        t_m_masked = obj.sig_m(mask_trim);
                        t_s_masked = obj.sig_s(mask_trim);
                        ratio = t_s_masked./t_m_masked;
                        obj.sig_s(mask_trim) = ratio;
                    end
                    obj.sig_m = tmp;
                case 'n'
                    disp('No trimming of transmittance values');
            end
        end
        
        function transmittance2XYZ(obj, trim)
            %transmittance2XYZ
            % [mean(T), stddev(T)] -> [XYZ, CovXYZ]
            
            % Trim transmittance values to max 1
            obj.trimTransmittance(trim);
            
            ls_array = repmat(obj.ls, 1, size(obj.sig_m, 2));
            
            disp('Calculate XYZ...')
            obj.spd2XYZ(ls_array);
            
            disp('Calculate CovXYZ...')
            obj.stddev_spd2CovXYZ(ls_array);

        end
        
        function transmittance2LAB(obj, trim)
            %transmittance2LAB
            % [mean(T), stddev(T)] -> [LAB, CovLAB]
            
            % T -> XYZ
            obj.transmittance2XYZ(trim)
            
            % XYZ -> LAB
            disp('Calculate LAB...')
            obj.XYZ2lab;
            
            disp('Calculate CovLAB...')
            obj.CovXYZ2Covlab;
        end
        
        %% sRBG coordinates
        function XYZ2sRGB(obj)
            %XYZ2sRGB
            % XYZ to RGB linear and gamma correction to get sRGB
            
            % Constants
            m=[3.2410 -1.5374 -0.4986; -0.9692 1.8760 0.0416; 0.0556 -0.2040 1.0570];
            a=0.055;
            
            % Linearize
            rgb_out = m*obj.XYZ'/obj.Y0;
            
            % Conditional mask
            rgb_lessorequal = (rgb_out <= 0.0031308);
            
            % Conditional assignment
            rgb_out(rgb_lessorequal) = rgb_out(rgb_lessorequal) * 12.92;
            rgb_out(~rgb_lessorequal) = (1+a)*(rgb_out(~rgb_lessorequal).^(1/2.4)) - a;
            
            % Clip
            rgb_out = double(uint8(rgb_out*255))/255;
            
            % Comply with the old form
            obj.rgb = rgb_out';
        end
        
        function transmittance2sRGB(obj, trim)
            %transmittance2sRGB
            % T -> sRBG with an intermediate step computating [XYZ, CovXYZ]
            
            % T -> XYZ
            obj.transmittance2XYZ(trim)
            
            % Compute sRGB values
            disp('Compute sRGB');
            obj.XYZ2sRGB;
        end
        
        %% Display results in a table
        function displ_res(obj, pix_pos)
            %displ_res
            % Display results on commad window for pixel position = [x, y]
            
            % Convert pixel position of row position
            r_pos = obj.pix_pos2r_pos(pix_pos);
            
            % Call chromaticity computation function
            xy = obj.XYZ2xy;
            
            % Data
            dt = [pix_pos obj.XYZ(r_pos, :) obj.XYZ(r_pos, 2) xy(r_pos, :) obj.LAB(r_pos, :)];
            
            % Header1
            h1 = {'X0' 'Y0' 'Z0'};
            h2 = {'PosX' 'PosY' 'X' 'Y' 'Z' 'Y' 'x' 'y' 'L' 'a' 'b'};

            % Display tabulated data
            fprintf(1, '\n%s\t\t%s\t\t%s\n', h1{:});
            fprintf(1, '%3.2f\t%3.2f\t%3.2f\n\n', obj.XYZ0);
            fprintf(1, '%s\t%s\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\t\t%s\n', h2{:});
            fprintf(1, '%d\t\t%d\t\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\t%3.2f\n', dt');

        end
        
        %% Graphics
        function p = plot_t_spectra(obj, pos, Color)
            %plot_t_spectra
            % Plot the transmittance for a table of positions:
            % - pixels positions [x y]
            % - list positions x
            % The color of the plots is defined by the rgb coordinates of
            % the pixels if the rbg matrix is not empty, if empty or no
            % color setting, the colors follow the colororder of the figure.
            
            % Convert pixel position of row position if needed
            if size(pos, 2) == 2
                r_pos = obj.pix_pos2r_pos(pos);
            elseif size(pos, 2) == 1
                r_pos = pos;
            end
            
            % Graphics
            figure;
            
            % Plot transmittance of pixels as a function of wavelength
            p = plot(obj.lambda, obj.sig_m(:, r_pos)');
            
            % Color
            switch Color
                case 'rgb'
                    if ~isempty(obj.rgb)
                        c = obj.rgb;
                        set(p, {'color'}, num2cell(c(r_pos, :), 2));
                    end
                case 'colororder'
            end
            xlim([390 770]); ylim([0 1.5]);
            xlabel('Wavelength ({\lambda})');
            ylabel('Transmittance (A.U.)');
        end
        
        function p = errorbar_t_spectra(obj, pos, Color)
            %errorbar_t_spectra
            % Plot the transmittance for a table of positions:
            % - pixels positions [x y]
            % - list positions x
            % The color of the plots is defined by the rgb coordinates of
            % the pixels if the rbg matrix is not empty, if empty or no
            % color setting, the colors follow the colororder of the figure.
            
            % Convert pixel position of row position if needed
            if size(pos, 2) == 2
                r_pos = obj.pix_pos2r_pos(pos);
            elseif size(pos, 2) == 1
                r_pos = pos;
            end
            
            % Graphics
            figure;
            
            % Color
            if ~isempty(obj.rgb)
                c = obj.rgb;
            end
            
            for i = 1:length(r_pos)
                p = errorbar(obj.lambda, obj.sig_m(:, r_pos(i))', 2*obj.sig_s(:, r_pos(i))');
                
                % Color
                switch Color
                    case 'rgb'
                        if ~isempty(obj.rgb)
                            set(p, 'Color', c(r_pos(i), :));
                        end
                end
                hold on;
            end
            xlim([390 770]); ylim([0 1.5]);
            xlabel('Wavelength ({\lambda})');
            ylabel('Transmittance (A.U.)');
        end
        
        function scatter3(obj, coord)
            %scatter3
            % scatter3 plot of the LAB, XYZ or sRGB coordinates
            % The color of the points is defined by the rgb coordinates of
            % the pixels if the rbg matrix is not empty
            
            % Color of points
            if ~isempty(obj.rgb)
                c = obj.rgb;
            else
                c = [0 0 0];
            end
            
            % Scatter 3D plot
            switch coord
                case 'LAB'
                    dt = obj.LAB;
                    % Columns swap to display L* on z axis, b* on x axis
                    % plot
                    dt(:, [1 3]) = dt(:, [3 1]);
                    fig = scatter3_LAB(dt(:, 1), dt(:, 2), dt(:, 3), [], c);
                case 'XYZ'
                    dt = obj.XYZ;
                    fig = scatter3_XYZ(dt(:, 1), dt(:, 2), dt(:, 3), [], c);
                case 'RGB'
                    dt = obj.rgb;
                    fig = scatter3_RBG(dt(:, 1), dt(:, 2), dt(:, 3), [], c);
               otherwise
                    disp('scatter3 options: LAB, XYZ or RGB');
                    return;
            end
             
            function fig = scatter3_LAB(X1,Y1,Z1,S1,C1)
                % Create figure
                fig = figure;
                
                % Create axes
                axes1 = axes('Parent',fig);
                hold(axes1,'on');
                
                % Create scatter3
                scatter3(X1,Y1,Z1,S1,C1,'Marker','.');
                
                % Create zlabel
                zlabel('L*');
                
                % Create ylabel
                ylabel('a*');
                
                % Create xlabel
                xlabel('b*');
                
                view(axes1,[-45 22.75]);
                grid(axes1,'on');
                axis(axes1,'ij');
                
                % Data cursor
                c_txt = {'b*' 'a*' 'L*'};
                dcm_obj = datacursormode(fig);
                set(dcm_obj, 'UpdateFcn',{@obj.dt_cursor_updatefcn, c_txt}); % To customize data output of data cursor
            end
            
            function fig = scatter3_XYZ(X1,Y1,Z1,S1,C1)
                % Create figure
                fig = figure;
                
                % Create axes
                axes1 = axes('Parent',fig);
                hold(axes1,'on');
                
                % Create scatter3
                scatter3(X1,Y1,Z1,S1,C1,'Marker','.');
                
                % Create zlabel
                zlabel('Z');
                
                % Create ylabel
                ylabel('Y');
                
                % Create xlabel
                xlabel('X');
                
                view(axes1,[46.8 31.2]);
                grid(axes1,'on');
                
                % Data cursor
                c_txt = {'X' 'Y' 'Z'};
                dcm_obj = datacursormode(fig);
                set(dcm_obj, 'UpdateFcn',{@obj.dt_cursor_updatefcn, c_txt}); % To customize data output of data cursor
            end
            
            function fig = scatter3_RBG(X1,Y1,Z1,S1,C1)
                % Create figure
                fig = figure;
%                 fig = figure('DeleteFcn', 'datacursormode');
                
                % Create axes
                axes1 = axes('Parent',fig);
                hold(axes1,'on');
                
                % Create scatter3
                scatter3(X1,Y1,Z1,S1,C1,'Marker','.');
                
                % Create zlabel
                zlabel('B');
                
                % Create ylabel
                ylabel('G');
                
                % Create xlabel
                xlabel('R');
                
                view(axes1,[135 22.75]);
                grid(axes1,'on');
                
                % Set the remaining axes properties
                set(axes1,'XDir','reverse','YDir','reverse');
                
                % Data cursor
                c_txt = {'R' 'G' 'B'};
                dcm_obj = datacursormode(fig);
                set(dcm_obj, 'UpdateFcn',{@obj.dt_cursor_updatefcn, c_txt}); % To customize data output of data cursor
            end
            
          end
    end
    
    methods (Access = private)
        
        function r_pos = pix_pos2r_pos(obj, pix_pos)
            %pix_pos2r_pos
            % Convert the pixel position [x, y] into the row position in
            % the data tables (number of rows = sizex * sizey)
            
            r_pos = (pix_pos(:, 1)-1).*obj.sizey + pix_pos(:, 2);
        end
        
        function txt = dt_cursor_updatefcn(obj, ~,event_obj, c_txt) %, c_order)
            %dt_cursor_updatefcn
            % Customizes text of data cursor for scatter3 graphics
            
            pos = get(event_obj,'Position');
            I = get(event_obj, 'DataIndex');
            txt = {[c_txt{1} ' ',num2str(pos(1))],...
                [c_txt{2} ' ',num2str(pos(2))],...
                [c_txt{3} ' ',num2str(pos(3))],...
                ['Index: ',num2str(I)]};
        end
    end
end