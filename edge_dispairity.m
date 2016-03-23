% right=imread('right3.jpg');
% left=imread('left3.jpg');
right=imright;
left=imleft;
s=size(left,2);
l=imresize(left,(400/s));
r=imresize(right,(400/s));
[l_edge,l_edge_complete]=eret(l);
[r_edge,r_edge_complete]=eret(r);

d=edgeDispairity(l_edge,r_edge,l,r);
x=d(:,:,1);
x=uint8(x);
% subplot(3,2,1),imshow(l),title('The left image');
% subplot(3,2,2),imshow(r),title('The right image');
% subplot(3,2,3),imshow(l_edge_complete),title('The edges in left image after removing horizontal edges');
% subplot(3,2,4),imshow(r_edge_complete),title('The edges in right image after removing horizontal edges');
% subplot(3,2,5),imshow(l_edge),title('The edge of right edge after cannys operation');
% subplot(3,2,6),imshow(r_edge),title('The edge of left edge after cannys operation');
x=imadjust(x,[10/255 100/255],[0 1]);
% x=imresize(x,4);
% figure,
imshow(x),title('The disparity map');