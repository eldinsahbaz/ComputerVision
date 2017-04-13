
function [morphed, foregrounds] = backgroundSub(e1, e2, alpha, beta)
    total = tic;
    %perform background subtraction
    [foregrounds] = BGS(e1, e2, alpha, beta);
    
    %perform morphology operations
    morphed = Morph(foregrounds);
    
    %convert to AVI format
    avi(morphed);
    disp(['total time: ', int2str(toc(total))])
end

function [] = avi(foregrounds)
    disp('*** avi ***')
    [~, cols] = size(foregrounds);
    
    %write each image to a jpeg file
    for i = 1:cols
        imwrite(foregrounds{i}, [int2str(i), '.jpg'])
    end
    
    %create a video writer object
    outputVideo = VideoWriter(fullfile('.\','test.avi'));
    open(outputVideo)

    %write each of the images previously created to the AVI file
    for i = 1:cols
        img = imread(fullfile('.\',[int2str(i), '.jpg']));
        writeVideo(outputVideo,img)
    end
    
    close(outputVideo)
    disp('*** BGS ***')
end

function [foregrounds2] = Morph(foregrounds)
    disp('*** Morph ***')
    [~, cols] = size(foregrounds);
    foregrounds2{cols} = [];
    
    %save the morphed images into a new cell array
    %perform closing of opening on foreground images
    for i = 1:cols
        foregrounds2{i} = imclose(imopen(foregrounds{i}, strel('disk',1)), strel('disk',5));
    end
end

function [foregrounds] = BGS(e1, e2, alpha, beta)
    disp('*** BGS ***')
    %get the images from the directory
    frames = readImages();
    %construct the codebook
    CB = codeBook(frames, e1, alpha, beta);
    [~, N] = size(frames);
    foregrounds{N} = [];
    
    %iterate over each framea
    for t = 1:N
        timer = tic;
        currentFrame = frames{t};
        [rows, cols, ~] = size(currentFrame);
        foregrounds{t} = zeros(rows, cols);
        
        %for each frame iterate over each pixel
        for j = 1:rows
            for k = 1:cols
                
                %get the RGB vector
                xt =[currentFrame(j,k,1), currentFrame(j,k,2), currentFrame(j,k,3)]; 
                
                %sum the RGB vector
                I = sum(xt);
                
                %initialize placeholders
                vm = {};
                aux = {};
                found = 0;
                
                %get the pixel's codebook
                entry = CB{j,k};
                [~, eC] = size(entry);
                
                %iterate over each codeword
                for l = 1:eC
                    %get the codeword's RGB vector and auxiliary vector
                    vm = entry{l}{1};
                    aux = entry{l}{2};
                    
                    %if color distortion is less than threshold e2 and
                    %brightness is true, the we found a match and break out
                    %of loop (stopping on first match)
                    if (colordist(xt, [vm.R, vm.G, vm.B]) <= e2) && brightness(I, aux.Imin, aux.Imax, alpha, beta)
                        found = found + 1;
                        break;
                    end
                end
                
                %if we found a match, then the pixel belongs to the
                %background otherwise it's a foreground pixel. We create a
                %binary foreground image for the current frame
                if found == 0
                    foregrounds{t}(j,k) = 255;
                else
                    foregrounds{t}(j,k) = 0;
                end                
            end
        end
        disp(['iteration: ', int2str(t), ', start: ', int2str(timer), ', end: ', int2str(toc(timer))])
    end
end

function [CB] = codeBook(frames, e1, alpha, beta)
    disp('*** codeBook ***')
    [~, N] = size(frames);
    CB = {};
    
    %create placeholders in codebook
    [tr, tc, ~] = size(frames{1});
    CB{tr,tc} = {};
    
    %iterate over each fram
    for t = 1:N
        timer = tic;
        currentFrame = frames{t};
        [rows, cols, ~] = size(currentFrame);
        
        %for each frame iterate over each pixel
        for j = 1:rows
            for k = 1:cols
                
                %get the RGB vector of the current pixel
                xt =[currentFrame(j,k,1), currentFrame(j,k,2), currentFrame(j,k,3)]; 
                
                %sum the current vector's RGB vector
                I = sum(xt);
                
                %initialize placeholders
                vm = {};
                aux = {};
                placement = 0;
                found = 0;
                
                %get the current pixel's corresponding codebook
                entry = CB{j,k};
                [~, eC] = size(entry);
                
                %iterate over each codeword in the codebook
                for l = 1:eC
                    
                    %get the codeword's RGB vector and auxiliary vector
                    vm = entry{l}{1};
                    aux = entry{l}{2};
                    placement = l;
                    
                    %if color distortion is less than threshold e2 and
                    %brightness is true, the we found a match and break out
                    %of loop (stopping on first match)
                    if (colordist(xt, [vm.R, vm.G, vm.B]) <= e1) && brightness(I, aux.Imin, aux.Imax, alpha, beta)
                        found = found + 1;
                        break;
                    end
                end
                
                %if we found a match then we update the fields in the RGB
                %struct (with the new average) and the fields in the
                %auxiliary struct. If there is no match, we create a new
                %codeword and put it in the codebook
                if found == 0
                    CB{j,k}{end+1} = {struct('R', xt(1), 'G', xt(2), 'B', xt(3)), struct('Imin', I, 'Imax', I, 'freq', 1, 'MNRL', t-1, 'p', t, 'q', t)};
                else
                    vm.R = (aux.freq*vm.R+xt(1))/(aux.freq+1);
                    vm.G = (aux.freq*vm.G+xt(2))/(aux.freq+1);
                    vm.B = (aux.freq*vm.B+xt(3))/(aux.freq+1);
                    aux.Imin = min(aux.Imin, I);
                    aux.Imax = max(aux.Imax, I);
                    aux.freq = aux.freq+1;
                    aux.MNRL = max(aux.MNRL, t-aux.q);
                    aux.q = t;
                    entry{placement} = {vm, aux};
                    CB{j,k} = entry;
                end                
            end
        end
        disp(['iteration: ', int2str(t), ', start: ', int2str(timer), ', end: ', int2str(toc(timer))])
    end
    
    %rim the codebook to get rid of unneccessary codewords
    CB = slim(CB, N);
    disp('*** BGS ***')
end

function [slimCB] = slim(CB, N)
    disp('*** slim ***')
    [rows, cols] = size(CB);
    slimCB{rows, cols} = {};
    
    %combine the MNRL adjustment and the slimming process into one loop by
    %first adjusting the MNRL then checking to see if it exceeds the
    %threhsold
    
    %iterate over each codebook
    for i = 1:rows        
        for j = 1:cols
            entry = CB{i,j};
            [~, cols2] = size(entry);
            
            %iterate over each code word and adjust its MNRL
            for k = 1:cols2
                entry{k}{2}.freq = max(entry{k}{2}.freq, (N - entry{k}{2}.q + entry{k}{2}.p - 1));
                
                %if the MNRL is less than the threshold then store it in
                %the new slim codebook
                if entry{k}{2}.MNRL <= N/2
                    slimCB{i,j}{end+1} = entry{k};
                end
            end
        end
    end
end

function [frames] = readImages()  
    disp('*** readImage ***')
    %read in all files in the current directy
    imagefiles = dir();      
    nfiles = length(imagefiles);
    frames = {};
    
    %iterate over each file in the current directory
    for i=1:nfiles
        %get the file name
        currentfilename = imagefiles(i).name;
        %only read every fifth file if it's an image. Otherwise, ignore it.
        
        if (sum(size(findstr('jpg', currentfilename))) >= 2) &&   (mod(i, 5) == 0)
            frames{end+1} = double(imread(currentfilename));
        end
    end
end

function [dist] = colordist(xt, vm)
    %take the square root of the values we get from subtracting the squared
    %dot product of the current RBG vector from the codewords RCB vector
    %divided by the magnitude of the codewords RGB vector from the squared
    %magnitude of the pixels RGB vector
    dist = sqrt((sqrt(sum(xt.^2))^2) - ((dot(xt,vm)^2)/(sqrt(sum(vm.^2))^2)));
end

function [isBetween] = brightness(I, IMin, IMax, alpha, beta)
    %the current pixels RGB vector sum is in the range of low and high
    %brightness values. The low brightness values is computed by
    %multiplying the codewords maximum brightness by some factor alpha. We
    %choose the value of alpha, but its typically between 0.4 and 0.7
    %(but always less than 1). Likewise, the high brightness is computed by
    %choosing the minimum values of either beta multiplied by the
    %codewords maximum brightness value (where beta is greater than 1) or
    %the codewords minimum brightness is divided by alpha. If the pixels
    %brightness falls into this range then we return true, otherwise false.
    
    Ilow = alpha*IMax;
    Ihi = min((beta*IMax), (IMin/alpha));
    isBetween = I >= Ilow && I <= Ihi;
end
