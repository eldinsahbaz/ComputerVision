README.txt
----------

To run the filtering process:

1) Open the m file in MATLAB

2) Pass the "myFilter" function the appropriate arguments:
    Myfilter(imgPath, AvgSize, GaussSize, MedianSize, sigma)
      imgPath = path to image on your computer
      AvgSize = kernel size for mean filter
      GaussSize = kernel size for Gaussian filter
      MedianSize = kernel size for Median filter
      sigma = standard deviation for Gaussain filter

3) Run the function

4) You now have three filtered images
    First filtered image: Mean filtering
    Second filtered image: Gaussian filtering
    Third filtered image: Median filtering

SideNote:
  I completed this assignment in MATLAB 2014a. There may be some differences
  in function names between my version and your version (if you are using a
  different version).
