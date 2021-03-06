%% Display pre-November 2014 ColorChecker Classic spectral data
% Plot spectral reflectances and display sRGB values for the ColorChecker
% Classic, from the data provided by Danny Pascale.
%
% ## Usage
% Modify the parameters, the first code section below, then run.
%
% ## Input
%
% ### CIE D-illuminant data file
% A '.csv' file containing the following columns (refer to the webpage by
% Bruce Lindbloom cited below):
% - Wavelength, in nanometres
% - The 'S_0' function value at the corresponding wavelength
% - The 'S_1' function value at the corresponding wavelength
% - The 'S_2' function value at the corresponding wavelength
%
% The Kelvin temperature of the illuminant must be provided in the script
% parameters section below.
%
% ### Spectral reflectances
% A '.csv' file containing a header row, a first column for wavelength
% values, and remaining columns for relative spectral reflectances of each
% patch in the ColorChecker chart.
%
% ### CIE tristimulus functions
% A '.mat' file containing a variable 'xyzbar', which can be used as the
% `C` input argument of 'cieSpectralToColor()'.
%
% ## Output
%
% ### Graphical output
% - Plots of the spectral reflectances of the ColorChecker chart patches,
%   with plotlines coloured by their sRGB colours
%
% ### Console output
% - sRGB values of the ColorChecker chart patches
%
% ## References
% - Foster, D. H. (2018). Tutorial on Transforming Hyperspectral Images to
%   RGB Colour Images. Retrieved from
%   http://personalpages.manchester.ac.uk/staff/d.h.foster/Tutorial_HSI2RGB/Tutorial_HSI2RGB.html
%   on June 5, 2018.
% - Lindbloom, Bruce J. (2017). Computing XYZ From Spectral Data. Retrieved
%   from http://www.brucelindbloom.com on June 11, 2018.
% - Lindbloom, Bruce J. (2017). Spectral Power Distribution of a CIE
%   D-Illuminant. Retrieved from http://www.brucelindbloom.com on June 4,
%   2018.
% - Pascale, Danny (2016). The ColorChecker Pages. Retrieved from
%   http://www.babelcolor.com/colorchecker.htm on June 4, 2018.

% Bernard Llanos
% Supervised by Dr. Y.H. Yang
% University of Alberta, Department of Computing Science
% File created June 7, 2018

%% Input data and parameters

% CIE D-illuminant
illuminant_filename = '${FILEPATH}';
illuminant_temperature = 5003; % From https://en.wikipedia.org/wiki/Standard_illuminant#Illuminant_series_D

% CIE tristimulus functions
xyzbar_filename = '${FILEPATH}';

% ColorChecker spectral reflectances
reflectances_filename = '${FILEPATH}';

%% Load and display the illuminant spectral power distribution

illuminant_data = csvread(illuminant_filename);
lambda_illuminant = illuminant_data(:, 1);
S_illuminant = illuminant_data(:, 2:end);
spd_illuminant = ciedIlluminant(...
    illuminant_temperature, lambda_illuminant, S_illuminant, lambda_illuminant...
);

figure;
plot(lambda_illuminant, spd_illuminant);
title(sprintf(...
    'CIE D-illuminant spectral power distribution for CCT = %g Kelvin',...
    illuminant_temperature...
    ));
xlabel('\lambda [nm]');
ylabel('Relative power');

%% Load and display ColorChecker spectral reflectances

colorChecker_table = readtable(reflectances_filename);
variable_names = colorChecker_table.Properties.VariableNames;
patch_names = variable_names(2:end);
lambda_colorChecker = colorChecker_table.(variable_names{1});
reflectances = colorChecker_table{:, 2:end};
n_patches = length(patch_names);

% Find patch colours
xyzbar_table = readtable(xyzbar_filename);
lambda_xyzbar = xyzbar_table{:, 1};
xyzbar = xyzbar_table{:, 2:end};

rgb = reflectanceToColor(...
    lambda_illuminant, spd_illuminant,...
    lambda_colorChecker, reflectances,...
    lambda_xyzbar, xyzbar...
    );
rgb_integer = floor(256 * rgb);

% Visualization
figure;
hold on
patch_names_legend = cell(n_patches, 1);
fprintf('ColorChecker patch sRGB colours under a CCT = %g Kelvin illuminant:\n', illuminant_temperature);
for i = 1:n_patches
    plot(...
        lambda_colorChecker, reflectances(:, i),...
        'Color', rgb(i, :), 'LineWidth', 2, 'Marker', 'none'...
    );
    % Recover original variable names, which contained spaces
    patch_names_legend{i} = strsplit(colorChecker_table.Properties.VariableDescriptions{i+1}, ':');
    patch_names_legend{i} = patch_names_legend{i}{end};
    if isempty(patch_names_legend{i})
        patch_names_legend{i} = colorChecker_table.Properties.VariableNames{i+1};
    end
    
    fprintf('\t%s: %d, %d, %d\n', patch_names_legend{i}, rgb_integer(i, 1), rgb_integer(i, 2), rgb_integer(i, 3));
end
hold off
title('ColorChecker spectral reflectances')
xlabel('\lambda [nm]')
ylabel('Relative spectral reflectance')
legend(patch_names_legend);