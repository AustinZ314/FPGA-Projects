% MATLAB code to take an image and generate a file of the image's RGB pixel values in hex format

% Read the image
I = imread('Gimp.jpg');	
imshow(I);
		
% Extract red, green and blue components from the image
R = I(:,:,1);			
G = I(:,:,2);
B = I(:,:,3);

% Make the numbers into doubles
R = double(R);	
G = double(G);
B = double(B);

% Raise each color value to the 4/8 power 
R = R.^(4/8); % 8 bits -> 4 bits
G = G.^(4/8); % 8 bits -> 4 bits
B = B.^(4/8); % 8 bits -> 4 bits

% Cast to integer
R = uint8(R); % float -> uint8
G = uint8(G);
B = uint8(B);

% Subtract one to avoid potential integer overflow from casting
R = R-1;
G = G-1;
B = B-1;

% Save color variables to a file in hex format for the chip to read
fileID = fopen ('Gimp.list', 'w');
for i = 1:size(R(:), 1)-1
    fprintf (fileID, '%x%x%x\n', R(i), G(i), B(i));
end
fprintf (fileID, '%x%x%x', R(size(R(:), 1)), G(size(G(:), 1)), B(size(B(:), 1)));
fclose (fileID);
