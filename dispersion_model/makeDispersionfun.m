function [ dispersionfun ] = makeDispersionfun(data, varargin)
% MAKEDISPERSIONFUN  Create a function to evaluate a model of disparity in three variables
%
% ## Syntax
% dispersionfun = makeDispersionfun(dispersion_data [, T])
%
% ## Description
% dispersionfun = makeDispersionfun(dispersion_data [, T])
%   Returns a function for evaluating model of disparity in terms of three
%   variables, X, Y, and lambda/colour channel.
%
% ## Input Arguments
%
% dispersion_data -- Model data
%   The `dispersion_data` output argument of 'xylambdaSplinefit()', or the
%   `polyfun_data` output argument of 'xylambdaPolyfit()'.
%
% T -- Coordinate transformation
%   A 3 x 3 transformation matrix applied to the spatial variables prior to
%   evaluating the model. For instance, `T` might convert the point
%   (x, y, 1), with 'x' and 'y', in pixel coordinates, to a coordinate
%   system having its origin at the centre of the image, and with 'x' and
%   'y' measured in millimetres. `T` is applied to homogenous coordinates,
%   and is assumed to be an affine transformation.
%
%   The inverse of `T` is applied to the disparity vectors produced by the
%   model, to convert them to the coordinate frame of the input. Note that
%   disparity vectors are unaffected by the translational component of the
%   inverse of `T`.
%
% ## Output Arguments
%
% dispersionfun -- Dispersion model
%   A function which takes an input 2D array 'xylambda', where the three
%   columns represent two spatial coordinates and a wavelength or colour
%   channel index, (x, y, lambda). The output of the function is a 2D
%   array, 'disparity', where the columns represent the x and y-components
%   of disparity vectors. 'disparity' is an evaluation of the models
%   in X, Y, and lambda for the two components of disparity vectors.
%
%   If 'xylambdaSplinefit()' or 'xylambdaPolyfit()', which created
%   `dispersion_data`, was modelling colour channels instead of
%   wavelengths, the third column of 'xylambda' should contain the indices
%   of the colour channels (corresponding to the indices of the second
%   dimension of `X`, the input argument of 'xylambdaSplinefit()' or
%   'xylambdaPolyfit()').
%
% ## References
%
% Part of this code was ported from the 3D thin plate splines code in the
% Geometric Tools library, written by David Eberly, available at
% https://www.geometrictools.com/GTEngine/Include/Mathematics/GteIntpThinPlateSpline2.h
% (File Version: 3.0.0 (2016/06/19))
%
% Geometric Tools is licensed under the Boost Software License:
%
% Boost Software License - Version 1.0 - August 17th, 2003
% 
% Permission is hereby granted, free of charge, to any person or organization
% obtaining a copy of the software and accompanying documentation covered by
% this license (the "Software") to use, reproduce, display, distribute,
% execute, and transmit the Software, and to prepare derivative works of the
% Software, and to permit third-parties to whom the Software is furnished to
% do so, all subject to the following:
% 
% The copyright notices in the Software and this entire statement, including
% the above license grant, this restriction and the following disclaimer,
% must be included in all copies of the Software, in whole or in part, and
% all derivative works of the Software, unless such copies or derivative
% works are solely in the form of machine-executable object code generated by
% a source language processor.
% 
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
% SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
% FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.
%
% See also xylambdaSplinefit, xylambdaPolyfit

% Bernard Llanos
% Supervised by Dr. Y.H. Yang
% University of Alberta, Department of Computing Science
% File created July 9, 2018

nargoutchk(1, 1);
narginchk(1, 2);

n_spatial_dim = 2;
n_models = length(data);
channel_mode = isfield(data, 'reference_channel');
if channel_mode
    reference_channel = find([data.reference_channel]);
end

if ~isempty(varargin)
    T_frame = varargin{1};
    T_frame_disparity = inv(T_frame);
    % The last column containing zeros is needed because disparity values
    % are vectors, and so cannot be translated.
    T_frame_disparity = [T_frame_disparity(:, 1:(end - 1)), zeros(size(T_frame, 1), 1)];
    for i = 1:n_models
        data(i).T_points = data(i).T_points * T_frame;
        % This next line relies on the assumption that both transformations
        % are affine, such that division by the homogenous coordinate is
        % not needed between the two transformations.
        data(i).T_disparity_inv = T_frame_disparity * data(i).T_disparity_inv;
    end
end

    function disparity_normalized = disparityNormalizedSpline(dataset_d, n_d)
        xy_normalized = (data(d).T_points * [dataset_d(:, 1:2), ones(n_d, 1)].').';
        if channel_mode
            xylambda_normalized = xy_normalized;
        else
            lambda_normalized = (data(d).T_lambda * [dataset_d(:, 3), ones(n_d, 1)].').';
            xylambda_normalized = [
                xy_normalized(:, 1:(end - 1)),...
                lambda_normalized(:, 1:(end - 1)),...
                ];
        end
        xylambda_normalized_3d = repmat(...
            permute(xylambda_normalized, [1 3 2]), 1, size(data(d).coeff_basis, 1)...
        );

        disparity_normalized = zeros(n_d, n_spatial_dim);
        for dim = 1:n_spatial_dim
            disparity_normalized(:, dim) = repmat(data(d).coeff_affine(1, dim), n_d, 1) +...
                dot(repmat(data(d).coeff_affine(2:end, dim), n_d, 1), xylambda_normalized, 2);
            distances = xylambda_normalized_3d - repmat(...
                permute(data(d).xylambda_training, [3, 1, 2]), n_d, 1, 1 ...
            );
            distances = sqrt(sum(distances .^ 2, 3));
            if channel_mode
                G = splineKernel2D(distances);
            else
                G = splineKernel3D(distances);
            end
            disparity_normalized(:, dim) = disparity_normalized(:, dim)  +...
                sum(repmat(data(d).coeff_basis(:, dim), 1, size(G, 2)) .* G, 2);
        end
    end

    function disparity_normalized = disparityNormalizedPoly(dataset_d, n_d)
        xy_normalized = (data(d).T_points * [dataset_d(:, 1:2), ones(n_d, 1)].').';
        lambda_normalized = (data(d).T_lambda * [dataset_d(:, 3), ones(n_d, 1)].').';
        xylambda_normalized = [
            xy_normalized(:, 1:(end - 1)),...
            lambda_normalized(:, 1:(end - 1)),...
            ];
        xylambda_normalized_3d = permute(xylambda_normalized, [1 3 2]);
        
        disparity_normalized = ones(n_d, 3);
        for j = 1:n_d
            vandermonde_vector = prod(...
                repmat(xylambda_normalized_3d(j, :, :), 1, data(d).n_powers, 1)...
                .^ data(d).powers, 3 ...
                );
            disparity_normalized(j, 1) = dot(vandermonde_vector, data(d).coeff_x);
            disparity_normalized(j, 2) = dot(vandermonde_vector, data(d).coeff_y);
        end
    end

    function disparity = modelfun(xylambda)
        n_all = size(xylambda, 1);
        disparity = zeros(n_all, n_spatial_dim);
        for d = 1:n_models
            if channel_mode
                if d == reference_channel
                    continue;
                end
                filter_d = (xylambda(:, 3) == d);
            else
                filter_d = true(n_all, 1);
            end
            dataset_d = xylambda(filter_d, :);
            n_d = size(dataset_d, 1);

            if strcmp(data(d).type, 'polynomial')
                disparity_normalized = disparityNormalizedPoly(dataset_d, n_d);
            elseif strcmp(data(d).type, 'spline')
                disparity_normalized = disparityNormalizedSpline(dataset_d, n_d);
            else
                error('Unrecognized value of the "type" field.');
            end
            
            disparity_d = (data(d).T_disparity_inv * disparity_normalized.').';
            disparity(filter_d, :) = disparity_d(:, 1:(end-1));
        end
    end

dispersionfun = @modelfun;
end

