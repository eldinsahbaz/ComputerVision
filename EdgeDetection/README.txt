README.txt
----------

To run the filtering process:

1) Rename the file EldinSahbaz_EdgeDetector.m to EdgeDetector.m then open the m file in MATLAB

2) Pass the "Corners" function the appropriate arguments:
    EdgeDetector(img, m, mu, sigma, tl, th)
      img = path to image on your computer
      m = kernel size for Gaussian filtering
      mu = mean of the Gaussian distribution
      sigma = standard deviation for Gaussain filter
      tN = low threshold for hysteresis thresholding
      th = high threshold for hysteresis thresholding

3) Run the function

4) output
    image with edges
