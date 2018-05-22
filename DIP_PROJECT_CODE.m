%                                                      OBJECT TRACKING USING TEMPLATE MATCHING
%                                                      GROUP MEMBERS :                                            
%                                                                      Ujwal Tandon
%--------------------------------------------------------------------------------------------------------------------------------------------------------------
clear all;
close all;
clc;
Source = videoinput('winvideo',1);                                          %Get camera input(Open youcam first to get the camera feed)
NFrames = 50;                                                               %Change the frame numbers here
Thresh = 40;                                                                %Threshhold to convert into binary image
Areathresh=2000;                                                            %Threshold for choosing the object
mov(1).cdata = getsnapshot(Source);                                         %Read in 1st frame as background frame
Background_frame=mov(1).cdata;
subplot 331,imshow(Background_frame);
title('Background Frame');
Background_grey = rgb2gray(Background_frame);                               %Convert background frame to greyscale

% -------------------------Set frame size variables--------------------------------------------------------------------------------------------------------------------------------------------------
Frame_size = size(Background_frame); 
Width = Frame_size(2);
Height = Frame_size(1);
fg = zeros(Height, Width);
% -------------------------Process frames----------------------------------------------------------------------------------------------------------------------------------------------------------

i=2;
while (1)
    mov(i).cdata = getsnapshot(Source); 
    Frame= mov(i).cdata;                                                    % Read in frame
    Frame_gray = rgb2gray(Frame);                                           % Convert frame to grayscale 
    Frame_diff = abs(double(Frame_gray) - double(Background_grey));         % Subtract current frame from background frame
    for j=1:Width 
        for k=1:Height
            if ((Frame_diff(k,j) > Thresh))
                fg(k,j) = Frame_gray(k,j);                                  % Detected objects are stored as a binary image
            else
                fg(k,j) = 0;
            end
        end
    end
    
    mask=logical(fg);
    mask = imopen(mask, strel('rectangle', [3,3]));                         % The morphological operations are performed to get proper objects
    mask = imclose(mask, strel('rectangle', [15, 15]));
    mask = imfill(mask, 'holes');
   
    subplot 332,imshow(mask);
    title('Background subtracted frame after processing');
                                                                            % Use vision.blobanalysis toolbox to set the properties of blobs(objects)
                                                                            % in the image
    hblob = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...          
           'AreaOutputPort', true, 'CentroidOutputPort', true, ...
           'MinimumBlobArea', Areathresh);
    [AREA, CENTROID, BBOX] = step(hblob, mask); 
                                                                              % Get the area ,centroid and bounding box parameters of the blobs
    mask = insertObjectAnnotation(Frame, 'rectangle', BBOX , 'Object');
    
    subplot 333,imshow(mask);
    title('Object with bounding box');
    
    areamax=max(AREA);
    if areamax > Areathresh
        ntotal=numel(BBOX);
        n=ntotal/4;
        x=zeros(n);
        y=zeros(n);
        w=zeros(n);
        h=zeros(n);
        for j=1:n
            x(j)=BBOX(j,1);
            y(j)=BBOX(j,2);
            w(j)=BBOX(j,3);
            h(j)=BBOX(j,4);
            Image=imcrop(Frame,[x(j) y(j) w(j) h(j)]);                     % Generate template of the object to be tracked
            subplot(3,3,4),imshow(Image);
            title('Template Image');
            imwrite(Image,sprintf('file%d_%d.jpg',i,n));     
            Templatename=sprintf('file%d_%d.jpg',i,n);        
        end    
        i=i+10;
%-----------------Template Matching-----------------------------------------------------------------------------------------------------------------------------------------------------        
        while 1,
            mov(i).cdata = getsnapshot(Source); 
            fr = mov(i).cdata;                                              % Read in frames 
            fr_g = rgb2gray(fr);
            htm=vision.TemplateMatcher;
            Template=imread(Templatename);
            Template_g=rgb2gray(Template);
            Loc=step(htm,fr_g,Template_g);                                  % Template matching with current frame
            a=isnan(Loc);
            if a==0  
            J =insertMarker(fr, Loc, 'circle', 'color', 'blue', 'size', 20);% Insert a marker on the object detected
            subplot 335,imshow(J);
            title('Tracked Object');
            else
            return;                                                         % If object to be detected is out of camera view then break and start again  
            end 
            i=i+10;
        end
    end
    i=i+10;
end
