README.txt
----------

To run the filtering process:

1) Open the m file in MATLAB

2) Pass the "Corners" function the appropriate arguments:
    Corners(img, m, mu, sigma, N, th)
      img = path to image on your computer
      m = kernel size for Gaussian filtering
      mu = mean of the Gaussian distribution
      sigma = standard deviation for Gaussain filter
      N = neighborhood size use for CORNERS
      th = threshold size used for filtering Eigen values

3) Run the function

4) output
    matrix of feature points where the first column corresponds
    to the Eigen value, the second column corresponds to the X
    coordinate, and the third column corresponds to the Y value.

    Entries that were flagged as removed are populated with [-1 -1 -1]

Note: I mention this in the report as well, but insertMarker doesn't work
(since I don't have access to the Computer Vision ToolBox). Because of this I can
only change the pixel color of the corner pixels. Consequently, the images, when imported
into the report, don't show the conrner pixels. So please look at the images in the zip file
while reviewing my results section of the report. Thank you!
