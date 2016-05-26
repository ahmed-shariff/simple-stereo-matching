function [horz_edge,image]=eret(i)
thresh=[0.00 0.2];
s=1.4;
i=rgb2gray(i);
% f=fspecial('log',5,0.5);
% image=imfilter(i,f);
% i=image+i;
% i=imsharpen(i,'Radius',5,'Amount',1.5);
% imshow(i);
% i=histeq(i);
horz_edge=edge(i,'canny',thresh,s);
% f=fspecial('gaussian',5,0.8);
% i=imfilter(i,f);
% horz_edge=edge(i,'log',0.003,2.2);
horz_edge=bwmorph(horz_edge,'thin');
image=horz_edge;
horz_edge=bwareaopen(horz_edge,2);
% imshow(image);

f=[-1 2 -1];
horz_edge=imfilter(horz_edge,f);

% to break  *  * type edges
%           **
f=[-1 1 0];
horz_edge=imfilter(horz_edge,f);

f=[-1 0 -1;0 2 0;0 0 0];
horz_edge=imfilter(horz_edge,f);

f=[0 0 0;0 2 0;-1 0 -1];
horz_edge=imfilter(horz_edge,f);
horz_edge=bwareaopen(horz_edge,2);
% imshow(horz_edge);