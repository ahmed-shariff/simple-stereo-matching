function [matches,matchCount]=aquireMatches(matches,x,y,n)

matchCount=0;
i=1;
j=x;
while i<100 && j<n
    j=x+i;
    if le(y,j)==1
        matchCount=matchCount+1;
        matches(matchCount,1)=i;%have j here for testing purposes
        matches(matchCount,2)=l(y,j);
        matches(matchCount,3)=abs(lmm(y,j,1)-rmm(y,x,1))+abs(lmm(y,j,2)-rmm(y,x,2))+abs(lmm(y,j,3)-rmm(y,x,3));
        matches(matchCount,4)=abs(lmm(y,j,4)-rmm(y,x,4))+abs(lmm(y,j,5)-rmm(y,x,5))+abs(lmm(y,j,6)-rmm(y,x,6));
    end
    i=i+1;
end