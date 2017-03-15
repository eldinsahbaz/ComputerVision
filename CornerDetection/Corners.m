%parent function
function [] = Corners(img, m, mu, sigma, N, th)
    img = imread(img);
    
    %check if the image is rgb.
    %if it is, convert it to grayscale
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    %Perform gaussian filtering on the image
    img = GaussianFilter(img, m, mu, sigma);
    
    %compute the gradients
    [Ex, Ey] = Gradient(img);
    
    %compute the list of eigen values with corresponding x and y
    %coordinates, then filter out all the overlapping Eigen values (by
    %flagging them. Then clean out all the flags, to leave only the corner
    %feature points. Then highlight these corner feature points on the
    %image and lastly, show the image.
    imshow(uint8(highlight(img, clean(filter(compute(Ex, Ey, N, th), N)))));
end

%displays feature points from pos on image
function [img] = highlight(img, pos)
    %get size of pos
    [rows, ~] = size(pos);
    
    %iterate over pos, setting each corner pixel to white in the image
    for i = 1:rows
        img(pos(i,1),pos(i,2)) = 255;
    end
    
    %convert image to uint8
    img = uint8(img);
end

%puts all non-flagged x and y coordinates into a new matrix, and returns
%that
function [newImg] = clean(pos)
    %get size of pos
    [rows, ~] = size(pos);
    
    %keep count (for adding to newImg)
    count = 1;
    
    %container for non-flagged entries
    newImg = [];
    
    %iterate over all rows in pos
    for i = 1:rows
        %if an entry is not -1, then add it to the new container and
        %increment count
        if pos(i,1) ~= -1
            newImg(count, 1) = pos(i,2);
            newImg(count, 2) = pos(i,3);
            count = count + 1;
        end
    end
end

%flags the overlapping entries for later removal
function [pos] = filter(pos, N)
    %get size of pos
    [rows, ~] = size(pos);
    
    %iterate over rows of pos
    for i = 1:rows
        %get the row and column values from pos
        curr_row = pos(i, 2);
        curr_col = pos(i, 3);
        
        %if the entry is not -1, then process. Otherwise, skip.
        if pos(i,1) ~= -1
            
            %iterate over all remaining rows
            for j = (i+1):rows
                %get the row and column values at j
                r_row = pos(j, 2);
                r_col = pos(j, 3);
                
                %check the boolean conditions at the boundaries
                rowCond = ((r_row <= (curr_row + N)) && (r_row >= (curr_row - N)));
                colCond = ((r_col <= (curr_col + N)) && (r_col >= (curr_col - N)));
                
                %make sure both conditions are true in order to flag for
                %removal
                if rowCond && colCond
                    pos(j,1) = (-1);
                    pos(j,2) = (-1);
                    pos(j,3) = (-1);
                end
            end
        end
    end
end

function [pos] = compute(Ex, Ey, N, th)
    %compute the size of the neighborhood
    SIZE = (2*N) + 1;
    
    %compute the neighborhoods via im2col - for both the X and Y gradient
    %images
    Nx = im2col(padarray(Ex, [N N]), [SIZE SIZE], 'sliding');
    Ny = im2col(padarray(Ey, [N N]), [SIZE SIZE], 'sliding');
    
    %get the sizes
    [~, col] = size(Nx);
    [Erow, Ecol] = size(Ex);
    
    %pos is a container for the eigen, row, and column values
    pos = [];
    
    %eigs is used for storing eigen values with the purpose of
    %normalization
    eigs = [];
    
    %used for tracking values
    count = 1;
    x = 0;
    y = 1;
    
    %iterate over all columns
    for i = 1:col
        %reconstruct the neighborhood
        tempX = reshape(Nx(:,i),SIZE, SIZE);
        tempY = reshape(Ny(:,i), SIZE, SIZE);
        
        %compute the sum of pixel-wise multplication between the X and Y
        %gradient neighborhoods
        combo = sum(sum(tempX.*tempY));
        
        %compute the sum of pixel-wise squaring between in the X
        %gradient neighborhoods
        Xsq = sum(sum(tempX.^2));
        
        %compute the sum of pixel-wise squaring between in the Y
        %gradient neighborhoods
        Ysq = sum(sum(tempY.^2));
        
        %Construct C
        C = [Xsq, combo; combo, Ysq];
        
        %Find and keep track of the minimum Eigen values
        eigs = [eigs min(eig(C))];
    end
    
    %take the range of computed Eigen values
    Range = max(eigs) - min(eigs);
    
    
    for i = 1:col
        %keep track of x and y values corresponding to the Eigen values
        x = x + 1;
        if mod(i, Erow) == 0
            x = 1;
            y = y + 1;
        end
        
        %same as above
        tempX = reshape(Nx(:,i),SIZE, SIZE);
        tempY = reshape(Ny(:,i), SIZE, SIZE);
        combo = sum(sum(tempX.*tempY));
        Xsq = sum(sum(tempX.^2));
        Ysq = sum(sum(tempY.^2));
        C = [Xsq, combo; combo, Ysq];
        
        %normalize the computed Eigen value before thresholding. If the
        %normalized value is greater than the threshold, add to pos.
        if ((min(eig(C)) - min(eigs))/(Range)) > th
            pos(count, 1) = min(eig(C));
            pos(count, 2) = x;
            pos(count, 3) = y;
            count = count + 1;
        end
    end
    
    %sort pos in descending order by the Eigen values
    pos = sortrows(pos, -1);
end

function [Ex, Ey] = Gradient(img)    
    %create the vectors to compute the gradient with - via convolution
    Gx = [1, 0, -1];
    Gy = [-1, 0, 1]';
    
    %compute the gradients
    Ex = conv2(double(img), double(Gx), 'same');
    Ey = conv2(double(img), double(Gy), 'same');
end

function [img] = GaussianFilter(img, m, mu, sigma)
%use my guassian kernel function to create a kernel
kernel = GaussKernel(m, mu, sigma);

%do convolution with the image and the kernel. 
%Then convert the matrix to a uint8 and display it.
img = uint8(conv2(double(kernel), double(reshape(kernel, m, 1)), double(img), 'same'));
end

function [x] = GaussKernel(m, mu, sigma)
%create a an array of length m
points = zeros([1 m]);

%use this to populate the points array with sampling points
position = -1*floor(m/2);
i = 1;

%Time-step T = 1
while i <= m
    points(i) = position;
    position = position + 1;
    i = i + 1;
end;

%sample from a gaussian distribtion
x = normpdf(points, mu, sigma);

%divide by the smallest number in the array
x = x/min(x);

%divide by the sum (averaging)
x = (x)/sum(x);
end
