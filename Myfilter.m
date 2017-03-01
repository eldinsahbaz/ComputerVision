function [] = Myfilter(imgPath, AvgSize, GaussSize, MedianSize, sigma)
%read the image and save it into a matrix
img = imread(imgPath);

AvgFilter(img, AvgSize);
figure;

%my gaussian filter
GaussianFilter(img, GaussSize, sigma);
figure;

%my median filter
MedianFilter(img, MedianSize);
end

function [] = AvgFilter(img, m)
%create a m x m kernel filled by ones
%then divide by the sum
kernel = ones(m, m)/(m^2);

%perfom 2D convolution with the kernel and the image and
%only return the area of the convolution that corresponds
%to the size of the image passed in the first argument
imshow(uint8(conv2(double(img), double(kernel), 'same')));
end

function [] = MedianFilter(img, m)
%filter distorts image if mask size is even.
%Therefore, increment size by 1 if m is even.
if mod(m, 2) == 0
    m = m + 1;
end

%use padarray to pad the matrix with zeros
%then use im2col to rearrange the m x m neighborhood into a column
mat = im2col(padarray(img, [floor(m/2) floor(m/2)]), [m m], 'sliding');

%take the transpose to make traversal easier
mat = mat.';

%we only care about the number of rows
[rows, ~] = size(mat);

%vector used to hold the median value of each row
medians = [];

%loop over all the rows in the transposed matrix
%sort each row and store the median value of the
%row into the medians vector
for i = 1: rows
    mat(i,:) = sort(mat(i,:), 'descend');
    medians = [medians median(mat(i,:))];
end

%store the row and column size of the image
[rows, cols] = size(img);

%for traversing the medians vector
z = 1;

%the im2col function traverses all the rows
%in the first column before moving onto the
%second column. So we traverse vertically
%rather than horizontally
for j = 1:cols
    for i = 1:rows
        
        %ij index of img gets replaced with
        %the corresponding median value
        img(i, j) = medians(z);
        z = z + 1;
    end
end

%convert the image to uint8 and display the image
imshow(uint8(img));
end

function [] = GaussianFilter(img, m, sigma)
%use my guassian kernel function to create a kernel
kernel = GaussKernel(m, sigma);

%do convolution with the image and the kernel. 
%Then convert the matrix to a uint8 and display it.
imshow(uint8(conv2(double(kernel), double(reshape(kernel, m, 1)), double(img), 'same')));
end

function [x] = GaussKernel(m, sigma)
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
x = normpdf(points, 0, sigma);

%divide by the smallest number in the array
x = x/min(x);

%divide by the sum (averaging)
x = (x)/sum(x);
end