README.txt
----------

To run the Background Subtraction (BGS) Code:

1) Open the backgroundSub m file in MATLAB

2) Pass the backgroundSub function the appropriate arguments:
     backgroundSub(e1, e2, alpha, beta)
     	e1 = threshold 1 (for color distortion in codebook construction)
     	e2 = threshold 2 (for color distortion in BGS)
	alpha = value to multiply brightness by for low brightness bound
	beta = value to multiply brightness by for high brightness bound

3) Run the function

4) output
	The code will output the foreground frames in the current directory
	and create an output AVI video from these foreground images