% Example computations related to material decomposition X-ray tomography. 
% Here we apply Tikhonov regularization and solve the normal equations 
% modified for two image system, using the conjugate gradient method.
%
% Needs: Spot-operator toolbox!
% phantoms for two materials
% functions: A2x2mult_matrixfree,
% A2x2mult_matrixfree_rotang,A2x2Tmult_matrixfree
%
% Jennifer Mueller and Samuli Siltanen, October 2012
% Modified by Salla 6.10.2020

clear all;
% Measure computation time later; start clocking here
tic
%% Choises for the user
% Choose the size of the unknown. The image has size NxN.
N       = 512;
% Choose the regularization parameters
alpha  = 500;             
beta  = alpha/2;
% Choose relative noise level in simulated noisy data
noiselevel = 0.01;
% Choose number of iterations
iter = 42;
% Choose measurement angles (given in degrees, not radians). 
Nang    = 65; 
angle0  = -90;
rotang  = 45; % Avoid inverse crime by rotating the phantom
ang     = angle0 + [0:(Nang-1)]/Nang*180;

%% Attenuation coefficients from NIST-database (divided by density).
c11     = 1.491; % PVC    30kV  (Low energy)
c12     = 8.561; % Iodine 30kV
c21     = 0.456; % PVC    50kV  (High energy)
c22     = 12.32; % Iodine 50kV

%% Construct phantom
% Option 1: HY letteres
% M1      = imread('material1.png');
% M2      = imread('material2.png');

% Option 2: Blob & spot phantoms
% M1 = phantom_blob(N);
% M2 = phantom_spot(N);
% figure(67)
% imshow(M1)
% figure(68)
% imshow(M2)

% Option 3: HY Logo
M1      = imread('hyA.png');
M2      = imread('hyB.png');
%%
% Select one of the channels
M1      = M1(:,:,1);
M2      = M2(:,:,1);

% Change to double
M1      = double(M1);
M2      = double(M2);

% Resize the image
M1      = imresize(M1, [N N], 'nearest');
M2      = imresize(M2, [N N], 'nearest');

% Avoid inverse crime by rotating the object (interpolation)
g1      = imrotate(M1,rotang,'bilinear','crop');
g2      = imrotate(M2,rotang,'bilinear','crop');

% Combine the vectors
g      = [g1(:);g2(:)];

%% Start reconstruction
% Simulate noisy measurements avoiding inverse crime 
m       = A2x2mult_matrixfree_rotang(c11,c12,c21,c22,g,ang,N,rotang); 
% Add noise/poisson noise
m  = m + noiselevel*max(abs(m(:)))*randn(size(m));
% m = imnoise(m,'poisson');

% Solve the minimization problem
%         min (x^T H x - 2 b^T x), 
% where 
%         H = A^T A + alpha*I
% and 
%         b = A^T mn.
% The positive constant alpha is the regularization parameter

b = A2x2Tmult_matrixfree(c11,c12,c21,c22,m,ang);
%%
% Solve the minimization problem using conjugate gradient method.
% See Kelley: "Iterative Methods for Optimization", SIAM 1999, page 7.
g   = zeros(2*N*N,1); % initial iterate is zeros instead of the backprojected data
rho = zeros(iter,1); % initialize parameters

%*** New Q2-regularization term****
% We create matrix Q2 by writing normal matrix M=[alpha, beta; beta, alpha]
% and then taking a kronecker product with opEye. Every element of M will 
% be multiplied with opEye which results a block matrix Q2.
pMatrix = [alpha, beta; beta, alpha];
opMatrix = opEye(N^2);
Q2 = kron(pMatrix,opMatrix);

Hg  = A2x2Tmult_matrixfree(c11,c12,c21,c22,A2x2mult_matrixfree(c11,c12,c21,c22,g,ang,N),ang) + Q2*g(:);
r    = b-Hg;
rho(1) = r(:).'*r(:);

% Start iteration
for kkk = 1:iter
    if kkk==1
        p = r;
    else
        bee = rho(kkk)/rho(kkk-1);
        p    = r + bee*p;
    end
    w          = A2x2Tmult_matrixfree(c11,c12,c21,c22,A2x2mult_matrixfree(c11,c12,c21,c22,p,ang,N),ang);
    w          = w + Q2*p;
    aS         = rho(kkk)/(p.'*w);
    g          = g + aS*p;
    r          = r - aS*w;
    rho(kkk+1) = r(:).'*r(:);
    
%     figure(1) % Show reconstruction of material 1
%     recn1 = reshape(g(1:(end/2),1:end),N,N);
%     imshow(recn1,[]);
% 
%     figure(2)    % Show the reconstruction with current iteration
%     recn2 = reshape(g((end/2)+1:end,1:end),N,N);
%     imshow(recn2,[]);
  
    % Observe the error
    CG1       = reshape(g(1:(end/2),1:end),N,N);
    CG2       = reshape(g((end/2)+1:end,1:end),N,N);
    err_CG1   = norm(M1(:)-CG1(:))/norm(M1(:));
    err_CG2   = norm(M2(:)-CG2(:))/norm(M2(:));
    % Total error calculated as mean of the errors of both reconstructions
    err_total = (err_CG1+err_CG2)/2; 
  
      format short e
    % Monitor the run
    disp(['Iteration ', num2str(kkk,'%4d'),', total error value ',num2str(err_total)])
    if err_total < 1*10^-6
        disp('Error below noise!')
        break;
    end
end
CG1 = reshape(g(1:(end/2),1:end),N,N);
CG2 = reshape(g((end/2)+1:end,1:end),N,N);

% Determine computation time
comptime = toc;

%% Compute the error
% Target 1
err_CG1    = norm(M1(:)-CG1(:))/norm(M1(:)); % Square error
SSIM1      = ssim(CG1,M1); % Structural similarity index
% Target 2
err_CG2    = norm(M2(:)-CG2(:))/norm(M2(:)); % Square error
SSIM2      = ssim(CG2,M2); % Structural similarity index
% Total error calculated as mean of the errors of both reconstructions
err_total  = (err_CG1+err_CG2)/2;

%% Save image
% Samu's version for saving:
% normalize the values of the images between 0 and 1
im1        = M1;     % material 1: PVC
im2        = M2;     % material 2: Iodine
im3        = CG1;   % segmentation of PVC
im4        = CG2;   % segmentation of Iodine

MIN        = min([min(im1(:)),min(im2(:)),min(im3(:)),min(im4(:))]);
MAX        = max([max(im1(:)),max(im2(:)),max(im3(:)),max(im4(:))]);
im1        = im1-MIN;
im1        = im1/(MAX-MIN);
im2        = im2-MIN;
im2        = im2/(MAX-MIN);
im3        = im3-MIN;
im3        = im3/(MAX-MIN);
im4        = im4-MIN;
im4        = im4/(MAX-MIN);
imwrite(uint8(255*im3),'CG1_reco.png')
imwrite(uint8(255*im4),'CG2_reco.png')

%HaarPSI index:
%HaarPSI(255*im1,255*im2) 


%% Take a look at the results
figure(4);
% Original phantom1
subplot(2,2,1);
imagesc(M1);
colormap gray;
axis square;
axis off;
title({'Phantom1, matrixfree'});
% Reconstruction of phantom1
subplot(2,2,2)
imagesc(CG1);
colormap gray;
axis square;
axis off;
title(['Approximate error ', num2str(round(err_CG1*100,1)), '%, \alpha=', num2str(alpha), ', \beta=', num2str(beta)]);
% Original target2
subplot(2,2,3)
imagesc(M2);
colormap gray;
axis square;
axis off;
title({'Phantom2, matrixfree'});
% Reconstruction of target2
subplot(2,2,4)
imagesc(CG2);
%imagesc(imrotate(CG2,-45,'bilinear','crop'));
colormap gray;
axis square;
axis off;
title(['Approximate error ' num2str(round(err_CG2*100,1)), '%, iter=' num2str(iter)]);