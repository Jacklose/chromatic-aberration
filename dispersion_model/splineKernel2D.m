function [ y ] = splineKernel2D(x)
% SPLINEKERNEL2D  2D thin-plate spline kernel function
%
% ## References
%
% This code was ported from the 3D thin plate splines code in the Geometric
% Tools library, written by David Eberly, available at
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
% See also splineKernel3D

% Bernard Llanos
% Supervised by Dr. Y.H. Yang
% University of Alberta, Department of Computing Science
% File created July 8, 2018

nargoutchk(1, 1);
narginchk(1, 1);

y = zeros(size(x));
filter = x > 0;
x2 = x(filter) .^ 2;
y(filter) = x2 * log(x2);