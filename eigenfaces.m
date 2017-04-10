function [] = eigenfaces(n, distance_threshold)
    %split data into a training set and a testing set
    %follows the 80-20 rule
    [trainingSet, testingSet] = splitDataset();
    
    %calculate the mean face from the training set
    avg = avgFace(trainingSet);
    
    %subtract the mean face from each training face image
    A = double(subtract(trainingSet, avg));
    
    %get the number of rows and columns of A
    [Arows, Acols] = size(A);
    
    %i is the starting time and i_ is the ending time of this PCA operation
    %compute the eigen values and vectors of A*A'
    i = tic;
    [iVectors, iValues] = eig(A*(A'));
    i_ = toc(i);
    
    %ii is the starting time and ii_ is the ending time of this SVD operation
    %compute the eigen values and vectors of (1/sqrt(n-1))*A'
    ii = tic;
    [iiVectors, iiValues, ~] = svd(double((1/sqrt(Acols-1))*(A')));
    ii_ = toc(ii);
    
    %iii is the starting time and iii_ is the ending time of this PCA operation
    %compute the eigen values and vectors of A'*A, then perform matrix
    %multiplication between A and the eigenvectors to form the eigenfaces
    %matrix
    iii = tic;
    [iiiVectors, iiiValues] = eig(A'*A);
    eigenfaces = A*iiiVectors;
    iii_= toc(iii);
    
    %print out the starting and ending times for each of the 3 methods
    disp(['Start for b.i: ', char(i), ', end for b.i: ', int2str(i_)]);
    disp(['Start for b.ii: ', char(ii), ', end for b.ii: ', int2str(ii_)]);
    disp(['Start for b.iii: ', char(iii), ', end for b.iii: ', int2str(iii_)]);
    
    %compare results from the three PCA methods only if they have the same
    %size (otherwise we cannot compare them). If we can compare them, we
    %just want to see if we achieve the same results from each of the three
    %methods.
    [iVecRow, iVecCol] = size(iVectors);
    [iiVecRow, iiVecCol] = size(iiVectors);
    [iiiVecRow, iiiVecCol] = size(iiiVectors);
    [iValRow, iValCol] = size(iValues);
    [iiValRow, iiValCol] = size(iiValues);
    [iiiValRow, iiiValCol] = size(iiiValues);
    
    if iVecRow == iiiVecRow && iVecCol == iiiVecCol
        iVeciiiVec = iVectors == iiiVectors;
    end
    
    if iValRow == iiiValRow && iValCol == iiiValCol
        iValiiiVal = iValues == iiiValues;
    end
    
    if iVecRow == iiVecRow && iVecCol == iiVecCol
        iVeciiVec = iVectors == iiVectors;
    end
    
    if iValRow == iiValRow && iValCol == iiValCol
        iVeciiVal = iValues == iiValues;
    end
    
    if iiVecRow == iiiVecRow && iiVecCol == iiiVecCol
        iiVeciiiVec = iiVectors == iiiVectors;
    end
    
    if iiValRow == iiiValRow && iiValCol == iiiValCol
        iiValiiiVal = iiValues == iiiValues;
    end
    
    %normalize the eigenfaces one column vector at a time (i.e. one face at
    %a time).
    [~, efCols] = size(eigenfaces);
    for i = 1:efCols
        eigenfaces(:,i) = eigenfaces(:,i)/sqrt(sum(eigenfaces(:,i).^2));
    end
    
    %append the eigen values onto the eigenfaces and sort them in desceding
    %order. Once they're sorted, retrieve only the top n eigenfaces and
    %discard the rest.
    sorted = sortrows([diag(iiiValues) (eigenfaces')], -1);
    sorted((n+1):end, :) = [];
    eigenfaces = (sorted(:, 2:end));
    
    %subtract the mean face from each testing face images
    gamma = double(subtract(testingSet, avg));
    
    %compute the weights for the testing faces
    weights = (eigenfaces)*gamma;
    
    %compute the weights for the training images (for classification)
    trainingWeights = eigenfaces*A;
    
    [weightsRows, weightsCols] = size(weights);
    
    %instead of doing subtraction one column vector at a time, match the
    %column size of the average vector to the column size of the weights
    %vector. Now perform matrix multiplication on the transpose of the
    %eigenfaces matrix (to match dimensions) with the weights matrix and
    %add the average face.
    repeatedAverage = uint8(repmat(avg,weightsCols));
    repeatedAverage = repeatedAverage(1:Arows,:);
    reconstructed = uint8(eigenfaces'*weights) + repeatedAverage;

    %classify the test images
    classifications = classify(trainingWeights, weights, distance_threshold);
    [classificationsRow, classificationsCol] = size(classifications);
    
    %iterate through each of the classified images
    for i = 1:classificationsCol
        
        %if the image could not be classified, plot a black image. If the
        %image was classified, find the matched training image.
        if classifications(2,i) == -1
            imshow(uint8(zeros([154 116])))
        else
            imshow(uint8(reshape(trainingSet(:,classifications(2,i)), [154 116])))
        end
        
        figure;
        
        %plot the test image
        imshow(uint8(reshape(testingSet(:,classifications(1,i)), [154 116])))
        figure;
        
        %plot the reconstructed test image
        imshow(uint8(reshape(reconstructed(:,classifications(1,i)), [154 116])))
        figure;
    end
end

function [classification] = classify(training, testing, thresh)
    [trainingRow, trainingCol] = size(training);
    [testingRow, testingCol] = size(testing);
    classification = [];
    
    %iterate over all test images
    for i = 1:testingCol
        %inintalize the minimum distance
        minDistance = intmax;
        
        %retrieve the current test image
        currentTest = testing(:,i);
        
        %iterate over all training images
        for j = 1:trainingCol
            %compute the distance from the current test image to the
            %current training image
            distance = norm(training(:,j) - currentTest)^2;
            
            %if the distance is smaller than minDistance, this is the newly
            %matched training image
            if distance < minDistance
                classification(1,i) = i;
                classification(2,i) = j;
                minDistance = distance;
            end
        end
      
        %if minDistance is greater than our threshold, the face is either
        %not seen before or the test image is a non-face image. Therefore,
        %set the classification to -1.
        if minDistance > thresh
            classification(i,2) = -1;
        end
    end
end

function [trainingSet, testingSet] = splitDataset()  
    %read in all files in the current directy
    imagefiles = dir();      
    nfiles = length(imagefiles);
    testingSet = [];
    trainingSet = [];
    
    %iterate over each file in the current directory
    for i=1:nfiles
        %get the file name
        currentfilename = imagefiles(i).name;
        
        %only read the file if it's an image. Otherwise, ignore it.
        if sum(size(findstr('jpg', currentfilename))) >= 2
            currentimage = imread(currentfilename);
            
            %if it's an RGB image, convert to Gray Scale
            if size(currentimage,3) == 3
                currentimage = rgb2gray(currentimage);
            end
            
            %set the labels that belong to the training set and the labels
            %that belong to the testing set
            [row, col] = size(currentimage);
            trainingLabels = sum(size(findstr('centerlight', currentfilename))) + sum(size(findstr('happy', currentfilename))) + sum(size(findstr('glasses', currentfilename))) + sum(size(findstr('leftlight', currentfilename))) + sum(size(findstr('noglasses', currentfilename))) + sum(size(findstr('normal', currentfilename))) + sum(size(findstr('rightlight', currentfilename))) + sum(size(findstr('sad', currentfilename))) + sum(size(findstr('sleepy', currentfilename)));
            testingLabels = sum(size(findstr('surprised', currentfilename))) + sum(size(findstr('wink', currentfilename)));
            [TRow, TCol] = size(trainingSet);
            
            %if the current file is a training image, append to the
            %trainingSet. If the current file is a testing image or is a
            %non-face image, append to the testingSet. If the file is a
            %non-face image, first resize it to fit the rest of the images.
            if trainingLabels >= 2
                trainingSet = [trainingSet reshape(uint8(currentimage), [row*col 1])];
            elseif testingLabels >= 2
                testingSet = [testingSet reshape(uint8(currentimage), [row*col 1])];
            elseif sum(size(findstr('NonFace', currentfilename)))
               currentimage = imresize(currentimage, [154 116]);
               [row, col] = size(currentimage);
               testingSet = [testingSet reshape(uint8(currentimage), [row*col 1])]; 
            end
        end
    end
end

function [avg] = avgFace(X)
    [row, col] = size(X);
    avg = [0];
    
    %sum each column vector
    for i = 1:col
        avg = avg+X(:,i);
    end
    
    %divide by the number of images (i.e. number of columns)
    avg = avg./col;
end

function [phi] = subtract(X, avg)
    [row, col] = size(X);
    phi = [];
    
    %subtract each column vector of X by avg
    for i = 1:col
        phi = [phi (X(:,i) - avg)];
    end
end