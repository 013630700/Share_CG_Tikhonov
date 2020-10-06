function [P, pixelSize] = blob_phantom(targetSize)
%DUAL_MATERIAL_PHANTOM Phantom for computed tomography
%   [P, pixelSize] = DUAL_MATERIAL_PHANTOM(size) generates an image of a phantom. 
%   The phantom is a cross section of a plastic cylinder with
%   an outer diameter of 25 cm and an inner diameter of 24 cm, filled with
%   water. But now modified to have only one material, material 1. The different materials have the following identifying keys:
%   AIR     = 0
%   PLASTIC = 2
%   WATER   = 2
%   The output specifies the physical size of one pixel in centimeters.
%
%   Alexander Meaney, University of Helsinki, 2017 modified by Salla Latva-Äijö 2018

% Material definition constants
%DEF_PLASTIC     = 1;
DEF_WATER       = 1;
DEF_METAL       = 0;

% The image area is 32 cm by 32 cm.
pixelSize = 32 / targetSize;

% Create coordinate grid
[x, y] = meshgrid(-targetSize/2:targetSize/2-1, ...
                  -targetSize/2:targetSize/2-1);
x = pixelSize * x;
y = pixelSize * y;
              
% Create plastic
%plasticRadius = (25/2);
%plastic = sqrt((x+60).^2 + (y).^2) < (plasticRadius);
   
% Create water
waterRadius = (24/2);
water = sqrt(x.^2 + y.^2) < (waterRadius);

% Create inserts
insertRadius = 2;
insertRadius2 = 3;
insertLocation = 5/sqrt(2);    % Coordinate from center of phantom in cm
insert1 = sqrt((x - insertLocation).^2 + (y - insertLocation).^2) <= ...
               insertRadius2;
insert2 = sqrt((x - insertLocation).^2 + (y + insertLocation).^2) <= ...
               insertRadius;
insert3 = sqrt((x + insertLocation).^2 + (y + insertLocation).^2) <= ...
               insertRadius;
% insert4 = sqrt((x + insertLocation).^2 + (y - insertLocation).^2) <= ...
%                insertRadius;
           
P           = zeros(targetSize);
%P(plastic)  = DEF_PLASTIC;
P(water)    = DEF_WATER;
P(insert1)  = DEF_METAL;
P(insert2)  = DEF_METAL;
P(insert3)  = DEF_METAL;
% P(insert4)  = DEF_METAL;
end


