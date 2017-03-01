%EdgeDetector('Flowers.jpg', 5, 1, 2, 5, 7)
%EdgeDetector('Flowers.jpg', 5, 3, 3, 7, 10)

%parent function
function [] = EdgeDetector(img, m, mu, sigma, tl, th)
    %check if the high threshold is greater than the low threshold
    if tl >= th
        error('tl is not smaller than th');
    end
    
    %make sure that the thresholds are not negative
    if th < 0
        error('cannot have a negative threshold')
    end        
    
    %read the image
    img = imread(img);
    
    %check if the image is rgb.
    %if it is, convert it to greyscale
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    %get the size of the image
    [rows, cols] = size(img);
    
    %run canny enhancer
    [Es, Eo] = CannyEnhancer(img, m, mu, sigma, rows, cols);
    
    %run non-max suppression
    [I, Eo] = Nonmax_Suppression(Es, Eo, rows, cols);
    
    %run hysteresis thresholding
    I = Hysteresis_Thresh(I, Eo, rows, cols, tl, th);
    
    %display output
    imshow(uint8(I));
end

function [seen] = Hysteresis_Thresh(I, Eo, rows, cols, tl, th)
    %hold the x and y coordinates of the 5 longest edges
    xfirst = [];
    xsecond = [];
    xthird = [];
    xfourth = [];
    xfifth = [];
    yfirst = [];
    ysecond = [];
    ythird = [];
    yfourth = [];
    yfifth = [];
    
    %use this to store the edges
    seen = zeros(rows, cols, 3);
    
    %iterate over image
    for i = 1:rows
        for j = 1:cols
            
            %make sure the pixel is greater than the high threshold
            if (I(i,j) >= th)
                %empty the x and y coordinates
                xCoords = [];
                yCoords = [];
                
                %call the helper and store update the seen matrix, x and y
                %coordinate containers
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, i, j, tl, th);
            
                %get size of each vector
                [~, xSize] = size(xCoords);
                [~, firstSize] = size(xfirst);
                [~, secondSize] = size(xsecond);
                [~, thirdSize] = size(xthird);
                [~, fourthSize] = size(xfourth);
                [~, fifthSize] = size(xfifth);
                
                %compare the sizes and update the necessary containers
                %(used for coloring later)
                if xSize > firstSize
                    xfifth = xfourth;
                    xfourth = xthird;
                    xthird = xsecond;
                    xsecond = xfirst;
                    xfirst = xCoords;
                    
                    yfifth = yfourth;
                    yfourth = ythird;
                    ythird = ysecond;
                    ysecond = yfirst;
                    yfirst = yCoords;
                elseif xSize > secondSize
                    xfifth = xfourth;
                    xfourth = xthird;
                    xthird = xsecond;
                    xsecond = xCoords;
                    
                    yfifth = yfourth;
                    yfourth = ythird;
                    ythird = ysecond;
                    ysecond = yCoords;
                elseif xSize > thirdSize
                    xfifth = xfourth;
                    xfourth = xthird;
                    xthird = xCoords;
                    
                    yfifth = yfourth;
                    yfourth = ythird;
                    ythird = yCoords;
                elseif xSize > fourthSize
                    xfifth = xfourth;
                    xfourth = xCoords;
                    
                    yfifth = yfourth;
                    yfourth = yCoords;
                elseif xSize > fifthSize
                    xfifth = xCoords;
                    
                    yfifth = yCoords;
                end
            end
        end
    end
    
    %get the sizes of the top 5 x and y coordinate containers
    [~, firstSize] = size(xfirst);
    [~, secondSize] = size(xsecond);
    [~, thirdSize] = size(xthird);
    [~, fourthSize] = size(xfourth);
    [~, fifthSize] = size(xfifth);
    
    %iterate over each of the top 5 and assign different colors to the
    %edges
    for k = 1:firstSize
        seen(xfirst(k), yfirst(k),1) = 255;
        seen(xfirst(k), yfirst(k),2) = 0;
        seen(xfirst(k), yfirst(k),3) = 0;
    end
    
    for k = 1:secondSize
        seen(xsecond(k), ysecond(k),1) = 0;
        seen(xsecond(k), ysecond(k),2) = 255;
        seen(xsecond(k), ysecond(k),3) = 0;
    end
    
    for k = 1:thirdSize
        seen(xthird(k), ythird(k),1) = 0;
        seen(xthird(k), ythird(k),2) = 0;
        seen(xthird(k), ythird(k),3) = 255;
    end
    
    for k = 1:fourthSize
        seen(xfourth(k), yfourth(k),1) = 225;
        seen(xfourth(k), yfourth(k),2) = 125;
        seen(xfourth(k), yfourth(k),3) = 25;
    end
    
    for k = 1:fifthSize
        seen(xfifth(k), yfifth(k),1) = 200;
        seen(xfifth(k), yfifth(k),2) = 50;
        seen(xfifth(k), yfifth(k),3) = 125;
    end
end

function [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x, y, tl, th)
    %get the size of the image I
    [rows, cols] = size(I);
    
    %if this image has not been seen before and the pixel is greater than
    %the low threshold (if it's greater than the high threshold then it'll
    %be greater than the low threshold as well -- note for the first call).
    if (seen(x, y) == 0 && I(x, y) >= tl)
        
        %get the edge orientation (normal to edge direction) and offset by
        %90 degrees
        d1 = Discretize(Eo(x, y)+90);
        %default color for every edge -- white
        seen(x,y,:) = 255;
        
        %update the x and y coordiantes
        xCoords = [xCoords x];
        yCoords = [yCoords y];
        
        %if d1 is 0 then go left and right
        %if d1 is 45 then go up-right and down-left
        %if d1 is 90 then go up and down
        %if d1 is 135 then go up-left and down-right
        if (d1 == 0)

            if(y < cols)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x, y+1, tl, th);
            end

            if (y > 1)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x, y-1, tl, th);
            end
        elseif (d1 == 45)

            if(x > 1 && y < cols)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x-1, y+1, tl, th);
            end

            if(x < rows && y > 1)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x+1, y-1, tl, th);
            end
        elseif (d1 == 90)

            if(x > 1)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x-1, y, tl, th);
            end

            if(x < rows)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x+1, y, tl, th);
            end
        elseif (d1 == 135)

            if(x > 1 && y > 1)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x-1, y-1, tl, th);
            end

            if(x < rows && y < cols)
                [seen, xCoords, yCoords] = Hysteresis_Helper(I, Eo, seen, xCoords, yCoords, x+1, y+1, tl, th);
            end 
        end
    end
end

function [I, Eo] = Nonmax_Suppression(Es, Eo, rows, cols)
    %create a new image
    I = zeros(rows, cols);
    
    %iterate over each row and column (i.e. every pixel)
    for i = 1:rows
        for j = 1:cols
            
            %discretize the edge orientation
            direction = Discretize(Eo(i,j));
            
            %suppressed is a flag to see if the pixel has been suppressed
            %or not. If the pixel is smaller than either of its neighbors
            %along the edge orientation, then we set that pixel to 0 in I
            %and set suppressed to 1. Then we check if suppressed is 1 or
            %not. If suppressed is not 1, then that means that the pixel is
            %greater than or equal to one or both of its neighbors along
            %the edge orientation, and we set that pixel in I to the edge
            %strength
            
            %if d1 is 0 then go left and right
            %if d1 is 45 then go up-right and down-left
            %if d1 is 90 then go up and down
            %if d1 is 135 then go up-left and down-right
            if (direction == 0)
                suppressed = 0;
                
                if (j > 1 && Es(i,j) < Es(i,j-1))
                    suppressed = 1;
                    I(i,j) = 0;
                end
                
                if (j < cols && Es(i,j) < Es(i,j+1))
                    suppressed = 1;
                    I(i, j) = 0;
                end
                
                if (suppressed ~= 1)
                    I(i,j) = Es(i,j);
                end
            elseif (direction == 45)
                suppressed = 0;
                
                if (i < rows && j > 1 && Es(i,j) < Es(i+1,j-1))
                    suppressed = 1;
                    I(i,j) = 0;
                end
                
                if (i > 1 && j < cols && Es(i,j) < Es(i-1,j+1))
                    suppressed = 1;
                    I(i, j) = 0;
                end
                
                if (suppressed ~= 1)
                    I(i,j) = Es(i,j);
                end
            elseif (direction == 90)
                suppressed = 0;
                
                if (i > 1 && Es(i,j) < Es(i-1,j))
                    suppressed = 1;
                    I(i,j) = 0;
                end
                
                if (i < rows && Es(i,j) < Es(i+1,j))
                    suppressed = 1;
                    I(i, j) = 0;
                end
                
                if (suppressed ~= 1)
                    I(i,j) = Es(i,j);
                end
            elseif (direction == 135)
                suppressed = 0;
                
                if (i > 1 && j > 1 && Es(i,j) < Es(i-1,j-1))
                    suppressed = 1;
                    I(i,j) = 0;
                end
                
                if (i < rows && j < cols && Es(i,j) < Es(i+1,j+1))
                    suppressed = 1;
                    I(i, j) = 0;
                end
                
                if (suppressed ~= 1)
                    I(i,j) = Es(i,j);
                end
            end
        end
    end
end

function [x] = Discretize(x)
    
    %if x is negative, shift by 180 degrees to make it a positive number
    if x < 0
        x = 180 + x;
    end

    %0 <= x < 22.5 & 157.5 <= 157.5 <= 180 --> 0
    %22.5 <= x < 67.5 --> 45
    %67.5 <= x < 112.5 --> 90
    %112.5 <= x < 157.5 --> 135
    if ((x >= 0 && x < 22.5) || (x >= 157.5 && x <= 180))
        x = 0;
    elseif (x >= 22.5 && x < 67.5)
        x = 45;
    elseif (x >= 67.5 && x < 112.5)
        x = 90;
    elseif (x >= 112.5 && x < 157.5)
        x = 135;
    end
    
end

function [Es, Eo] = CannyEnhancer(img, m, mu, sigma, rows, cols)
    %read the image
    img = GaussianFilter(img, m, mu, sigma);
    
    %create the vectors to compute the gradient with
    Gx = [1, 0, -1];
    Gy = [-1, 0, 1]';
    
    %compute the gradient
    Jx = conv2(double(img), double(Gx), 'same');
    Jy = conv2(double(img), double(Gy), 'same');
   
    %create the containers for the edge strength and the edge orientation
    Es = zeros(rows, cols);
    Eo = zeros(rows, cols);

    %iterate over the x and y gradients and compute the edge strength and
    %edge orientation for each pixel
    for i = 1:rows
        for j = 1:cols
            Es(i,j) = sqrt((Jx(i,j)^2)+(Jy(i,j)^2));
            Eo(i,j) = Discretize(atan(Jy(i,j)/Jx(i,j))*(180/pi));
        end
    end
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
