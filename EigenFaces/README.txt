README.txt
----------

To run the eigenfaces Code:

1) Extract all the images from the DataSet zip file into the same file as eigenfaces.m
	Since the images were not originally in jpeg format
	I wrote a script to edit their extensions

2) Open the eigenfaces m file in MATLAB

2) Pass the "Contours" function the appropriate arguments:
     eigenfaces(n, distance_threshold)
     	n = n most significant eigenfaces, where n is a positive integer
     	distance_threshold = threshold for discerning between face images and non-face images

3) Run the function

4) output
	The code will plot each matched training, testing, and reconstructed image (in that order).
	If a test image is not matched, then the result will be a black image.