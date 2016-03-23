function d=edgeDispairity(le,re,lrgb,rrgb)

[l,l_obj_count]=bwlabel(le);
[r,r_obj_count]=bwlabel(re,8);
matchThreshold=50;
maxNumberOfmatches=35;
maxDispairityRange=120;
densityFactor=0.7;
% imtool(r);
% imtool(l);

temp=re;

r_potential_matches=zeros(r_obj_count,maxNumberOfmatches,2);
%********************************
%of the two layers, in the 3rd dimention
%1 - matching object label
%2 - count
%********************************

% r_matches= horzcat(zeros(r_obj_count,1),ones(r_obj_count,1));
r_matches=cell(r_obj_count,2);
%********************************
%array of edges corresponding final match
%will be altered when irregularities are met
%col1 - match
%col2 - which best match has been choosen(first, second, or so forth)
%********************************

l_matches=cell(l_obj_count,1);
[m,n]=size(re);
d=zeros(m,n,3);
%********************************
%d is the dispairty map, with disparity, and match info selected from the
%matches matrix below
%********************************
%array of potential matches
%col 1: offset (x-axis point when testing)
%col 2: left difference
%col 3: right difference


cordinate_list=cell(r_obj_count,1);
cordinate_list_second=cell(l_obj_count,1);
match_list=cell(m,n);

%****************Method-   aquireMatches
    function matches=aquireMatches(x,y,r_label)
        %********************************
        %array of potential matches
        %col 1: offset (x-axis point when testing)
        %col 2: matching edge lable
        %col 3: left difference
        %col 4: right difference
        %*********************************
        matches=uint16(zeros(maxNumberOfmatches,4));
        matchCount=0;
        i=1;
        j=x;
        while i<maxDispairityRange && j<n
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
        i=1;
        left_min_index=0;
        left_min=matchThreshold;
        right_min_index=0;
        right_min=matchThreshold;
        while i<=matchCount
            a=matches(i,3);
            b=matches(i,4);

            if a<matchThreshold || b<matchThreshold
                if left_min>a
                    left_min_index=i;
                    left_min=a;
                end
                if right_min>b
                   right_min_index=i;
                   right_min=b;
                end
            end
            i=i+1;
        end
        if right_min_index~=0 || left_min_index~=0
            if right_min_index~=0 && right_min_index==left_min_index
                r_potential_matches=updateMatches(r_potential_matches,matches(right_min_index,2),r_label);
            elseif right_min_index~=0 && left_min_index==0
                r_potential_matches=updateMatches(r_potential_matches,matches(right_min_index,2),r_label);
%                     display(matches(right_min_index,:));
            elseif left_min_index~=0 && right_min_index==0
                r_potential_matches=updateMatches(r_potential_matches,matches(left_min_index,2),r_label);
%                     display(matches(left_min_index,:));
            elseif matches(right_min_index,2)<matches(left_min_index,3)
                r_potential_matches=updateMatches(r_potential_matches,matches(right_min_index,2),r_label);
%                     display(matches(right_min_index,:));
            else
                r_potential_matches=updateMatches(r_potential_matches,matches(left_min_index,2),r_label);
%                     display(matches(left_min_index,:));
            end
        end
    end
%*****************Method- nextConnectedPixel
    function [x_,y_]=nextConnectedPixel(x,y)
        temp(y,x)=0;
        x_=x;
        y_=y;
        if temp(y,x+1)==1
            x_=x+1;
        elseif temp(y,x-1)==1
            x_=x-1;
        elseif temp(y+1,x)==1
            y_=y+1;
        elseif temp(y+1,x+1)==1
            y_=y+1;
            x_=x+1;
        elseif temp(y+1,x-1)==1
            y_=y+1;
            x_=x-1;
        elseif temp(y-1,x-1)==1
            y_=y-1;
            x_=x-1;
        elseif temp(y-1,x+1)==1
            y_=y-1;
            x_=x+1;
        elseif temp(y-1,x)==1
            y_=y-1;
        else
            x_=0;
        end
    end
%*****************Method- nextMaxVal
    function [maxVal,max_val_index]=nextMaxVal(index,i)
        sorted=sort(r_potential_matches(index,(r_potential_matches(index,:,2))~=0,2),'descend');
        %the net max val is represented by the value in r_matches{index,2},
        %if the value i is 1,return the next max val, or else the ith
        %possible max val
        matchnum=r_matches{index,2}+(i-1);
        if matchnum==maxNumberOfmatches
            maxVal=0;
        else
            if length(sorted)<matchnum
                maxVal=0;
                max_val_index=0;
            else
                maxVal=sorted(matchnum);
                max_val_index=find(r_potential_matches(index,:,2)==maxVal);
            end
            if length(max_val_index)>1
            %recheck
                sorted=r_potential_matches(index,(r_potential_matches(index,:,1)~=0),2);
                [sorted,sorted_indices]=sort(sorted,'descend');
                max_val_index=sorted_indices(matchnum);
            end
        end
    end
%*****************Method- addToMatches(match)
    function addToLMatches(index,match)
        l_match=l_matches{index,1};
        if isempty(l_match)
            l_matches{index,1}=match;
        else
            if isempty(find(l_match==match,1))
                l_match=horzcat(l_match,match);
                l_matches{index,1}=l_match;
            end
        end
    end
%*****************Method- removeFromRMatches
    function removeFromLMatches(index,match,all)
        if all
            l_matches{index,1}=[];
        else
            l_match=l_matches{index,1};
            if ~isempty(find(l_match==match,1))
                if size(l_match,2)==1
                    l_matches{index,1}=[];
                else
                    index_of_match=(l_match(:)==match);
                    l_matches{index,1}=l_match((~index_of_match));
                end
            end
        end
    end
%*****************Method- addToMatches(match)
    function addToRMatches(index,match)
        r_match=r_matches{index,1};
        if isempty(r_match)
            r_matches{index,1}=match;
        else
            if isempty(find(r_match==match,1))
                r_match=horzcat(r_match,match);
                r_matches{index,1}=r_match;
            end
        end
    end
%*****************Method- removeFromRMatches
    function removeFromRMatches(index,match,all)
        if all
            r_matches{index,1}=[];
        else
            r_match=r_matches{index,1};
            if ~isempty(find(r_match==match,1))
                if size(r_match,2)==1
                    r_matches{index,1}=[];
                else
                    index_of_match=(r_match(:)==match);
                    r_matches{index,1}=r_match((~index_of_match));
                end
            end
        end
    end
%*****************Method- finalizeMatch
    function finalizeMatchPhase1(index,max_val_index)
        match=r_potential_matches(index,max_val_index,1);
        match_pair=l_matches{match,1};
        if isempty(match_pair);
            addToLMatches(match,index);
            addToRMatches(index,match);
        else
            l_match_reset=0;
            c=cordinate_list{index,1};
            for i1=1:length(match_pair)
                index1=match_pair(i1);
                
                c1=cordinate_list{index1,1};
                if c(1,2)>c1(1,2)
                    maxyofupper=c1(size(c1,1),2);
                    minyoflower=c(1,2);
                else
                    maxyofupper=c(size(c,1),2);
                    minyoflower=c1(1,2);
                end
                %this could be part of a continues edge, yet broken
                %in this map. if thats the case they wil not
                %horizontally overlap. if they horizontally
                %overlap, they are different edges.
                %here, max and min is meant for the values of y, not the
                %position itself
                if  (minyoflower+1) < (maxyofupper-1) 
                    l_match_reset=1;
                    %if only one edge is maped to 'match' then compare
                    %the count of matches obtained for each edge to
                    %'match', and whichever has the highest count fill
                    %be mapped to 'match', while other moves to another
                    matchCount=0;
                    for i2=1:length(match_pair)
                        index2=match_pair(i2);
                        max_val_index2=(r_potential_matches(index2,:,1)==match);
                        maxVal2=r_potential_matches(index2,max_val_index2,2);
                        matchCount=matchCount+maxVal2;
                    end


                    if r_potential_matches(index,max_val_index,2)>matchCount
                        removeFromLMatches(match,index,1);
                        addToLMatches(match,index);
                        addToRMatches(index,match);
                        for i2=1:length(match_pair)
                            index2=match_pair(i2);
                            r_matches{index2,2}=r_matches{index2,2}+1;
                            removeFromRMatches(index2,match,0);
                            [next_max_val,nmax_val_index]=nextMaxVal(index2,1);
                            if next_max_val~=0
                                %repeat with nmax_val_index
                                finalizeMatchPhase1(index2,nmax_val_index);
                            end
                        end
                    else
                        removeFromLMatches(match,index,0);
                        removeFromRMatches(index,match,0);
                        r_matches{index,2}=r_matches{index,2}+1;
                        [next_max_val,nmax_val_index]=nextMaxVal(index,1);
                        if next_max_val~=0
                            %repeat with nmax_val_index
                            finalizeMatchPhase1(index,nmax_val_index);
                        end
                    end
                end
                break;
            end
            if ~l_match_reset
                addToLMatches(match,index);
                addToRMatches(index,match);
            end
        end
        finalizeMatchPhase2(index);
    end
%*****************method- finalizeMatchp2
    function finalizeMatchPhase2(r_label)
        clist=cordinate_list{r_label,1};
        %there can be more than one matches already mapped to, clculcate
        %all matches in the list
        match_pair_r=r_matches{r_label,1};
        matchCount=0;
        for i=1:size(match_pair_r,1)
            match=match_pair_r(i);
            matchCount=matchCount+r_potential_matches(r_label,(r_potential_matches(r_label,:,1)==match),2);
        end   
        matchnum_i=2;
        [nmaxVal,nmax_val_index]=nextMaxVal(r_label,matchnum_i);
        while matchCount<(densityFactor*size(clist,1)) && nmaxVal~=0
            nmatch=r_potential_matches(r_label,nmax_val_index,1);
            maxminlist_nmatch=aquireCordinateMaxMin(nmatch);
            nmatch_suited=1;
            %check if the left matching edges are horizontally
            %overlaping with the new candidate edge
            for i=1:size(match_pair_r,1)
                match=match_pair_r(i);
                maxminlist=aquireCordinateMaxMin(match);
                if maxminlist(1,2)>maxminlist_nmatch(1,2)
                    maxyofupper=maxminlist_nmatch(2,2);
                    minyoflower=maxminlist(1,2);
                else
                    maxyofupper=maxminlist(2,2);
                    minyoflower=maxminlist_nmatch(1,2);
                end
                if (minyoflower+1)<(maxyofupper-1)
                    nmatch_suited=0;
                    break;
                end
            end


            if nmatch_suited
                match_pair_l=l_matches{nmatch,1};
                if isempty(match_pair_l)
                    addToLMatches(nmatch,r_label);
                    addToRMatches(r_label,nmatch);
                else
                    l_match_reset=0;
                    c_r=cordinate_list{r_label,1};
                    for i1=1:size(match_pair_l,1)
                        index1=match_pair_l(i1);
                        c_r1=cordinate_list{index1,1};
                        if c_r(1,2)>c_r1(1,2)
                            maxyofupper=c_r1(size(c_r1,1),2);
                            minyoflower=c_r(1,2);
                        else
                            maxyofupper=c_r(size(c_r,1),2);
                            minyoflower=c_r1(1,2);
                        end

                        if (minyoflower+1) < (maxyofupper-1)
                            l_match_reset=1;
                            matchCount1=0;
                            for i2=1:length(match_pair_l)
                                index2=match_pair_l(i2);
                                max_val_index2=(r_potential_matches(index2,:,1)==nmatch);
                                maxVal2=r_potential_matches(index2,max_val_index2,2);
                                matchCount1=matchCount1+maxVal2;
                            end
                            
                            if r_potential_matches(r_label,nmax_val_index,2)>matchCount1
                                matchCount=matchCount+nmaxVal;
                                removeFromLMatches(nmatch,r_label,1);
                                addToLMatches(nmatch,r_label);
                                addToRMatches(r_label,nmatch);
                                for i2=1:length(match_pair_l)
                                    index2=match_pair_l(i2);
                                    r_matches{index2,2}=r_matches{index2,2}+1;
                                    removeFromRMatches(index2,nmatch,0);
                                    [next_max_val,nmax_val_index]=nextMaxVal(index2,1);
                                    if next_max_val~=0
                                        %repeat with nmax_val_index
                                        finalizeMatchPhase1(index2,nmax_val_index);
                                    end
                                end
                            else
                                removeFromLMatches(nmatch,r_label,0);
                                removeFromRMatches(r_label,nmatch,0);
                            end
                        end
                    end
                    if ~l_match_reset
                        addToRMatches(r_label,nmatch);
                        addToLMatches(nmatch,r_label);
                        matchCount=matchCount+nmaxVal;
                    end
                end
            end
            matchnum_i=matchnum_i+1;
            [nmaxVal,nmax_val_index]=nextMaxVal(r_label,matchnum_i);
        end
    end
%*****************Method- aquireCordinateList
%used in finilizeMatches, thus 'temp' will be reassigned
%returnes the topmost and bottom most cordinates of a given edge
    function maxminlist=aquireCordinateMaxMin(l_label)
        maxminlist=cordinate_list_second{l_label,1};
        %maxminlist(1,:)=upper end cordinates(x,y)
        %maxminlist(2,:)=lower end cordinates(x,y)
    end

%*****************Method- setMatchMatrix
    function setMatchMatrix(x,y)
        j=1;
        avg=uint16(0);
        %average of each color on the left sode of the image
        for color=1:3
            k=x-j;
            while j<4 && j>0 && k>0
                avg=avg+uint16(rgbimage(y,k,color));
                j=j+1;
                k=x-j;
            end
            mm(y,x,color)=avg/(j-1);
            avg=0;
            j=1;
        end

        %average of each color on the right sode of the image
        for color=1:3
            k=x+j;
            while j<4 && j>0 && k<n
                avg=avg+uint16(rgbimage(y,k,color));
                j=j+1;
                k=x+j;
            end
            mm(y,x,color+3)=avg/(j-1);
            avg=0;
            j=1;
        end
    end


%***********execution starts here******************

mm=zeros(size(re,1),size(re,2),6);
rgbimage=rrgb;
%***********aquire cordinates of all pixels of each edge label
for y=1:m
    for x=1:n
        if temp(y,x)==1
            x_=x;
            y_=y;
            clist=[];
            r_label=r(y,x);
            while x_~=0% || (x_==7 && y_==178)
                c=[x_ y_];
                clist=vertcat(clist,c);
                setMatchMatrix(x_,y_);
                [x_,y_]=nextConnectedPixel(x_,y_);
            end
            cordinate_list{r_label,1}=clist;
        end
    end
end
rmm=mm;

%***************obtain all max and min of all l_edges*****
temp=le;
mm=zeros(size(re,1),size(re,2),6);
rgbimage=lrgb;
[m_,n_]=size(l);
for y1=1:m_
    for x1=1:n_
        if temp(y1,x1)==1
            x1_=x1;
            y1_=y1;
            l_label=l(y1,x1);
            upper=[x1,y1];
            while x1_~=0
                x1__=x1_;
                y1__=y1_;
                setMatchMatrix(x1_,y1_);
                [x1_,y1_]=nextConnectedPixel(x1_,y1_);
            end
            lower=[x1__,y1__];
            maxminlist=vertcat(upper,lower);
            cordinate_list_second{l_label,1}=maxminlist;
        end
    end
end
lmm=mm;
%*************getting the potential matches traversing through the
%*************cordinate list
for r_label=1:r_obj_count
    clist=cordinate_list{r_label,1};
    for count=1:size(clist,1)
            x=clist(count,1);
            y=clist(count,2);
            %aquire match
            matches=aquireMatches(x,y,r_label);
            match_list{y,x}=matches;
    end
end

%**********alternate method of traversing throught the 're' matrix
% for x=2:n-1
%     for y=2:m-1
%         if re(y,x)==1
%             r_label=r(y,x);
%             %aquire match
%             r_potential_matches=aquireMatches(r_potential_matches,x,y,r_label);
%         end
%     end
% end

%***************obtain a finilized list of matches


for index=1:r_obj_count
    maxVal=max(r_potential_matches(index,:,2));
    if maxVal~=0
        r_matches{index,2}=1;
        max_val_index=find(r_potential_matches(index,:,2)==maxVal);
        if length(max_val_index)>1
        %recheck
            sorted=r_potential_matches(index,(r_potential_matches(index,:,1)~=0),2);
            sorted=sort(sorted,'descend');
            max_val_index=find(r_potential_matches(index,:,2)==sorted(1),1);
        end
        finalizeMatchPhase1(index,max_val_index);
    end
end
%
%*******************Calculate dispairity*****************
for index=1:r_obj_count
    clist=cordinate_list{index,1};
    matching_l_label_list=r_matches{index,1};
%     display(index);
%     display(r_label_list);
    
    if ~isempty(matching_l_label_list)
        x_=0;
        y_=0;
        first_x=0;
        first_y=0;
        for k=1:size(clist,1)
            y=clist(k,2);
            x=clist(k,1);
            matches=match_list{y,x};
            match_label_index=[];
            j=1;
            %check which of the l_label that macthes this right edge that
            %is also matched to this perticular pixel from the matches list
            while (j <= size(matching_l_label_list,2))
                l_label=matching_l_label_list(j);
                match_label_index=find(matches(:,2)==l_label);
                if ~isempty(match_label_index)
                    break;
                end
                j=j+1;
            end
            
            %if there is an edge that matches this pixel that also matches
            %the corresponding edge it is on, then add the details of it to
            %the dispairity matrix
            if ~isempty(match_label_index)
                if size(match_label_index,1)~=1
                    match_label_index=match_label_index(1,1);
                end
                %record the first occured pixel in the list
                if first_x==0
                    first_x=x;
                    first_y=y;
                end
                d(y,x,1)=matches(match_label_index,1);
                d(y,x,2)=matches(match_label_index,3);
                d(y,x,3)=matches(match_label_index,4);
                x_=x;
                y_=y;
            %if this edge doesnt have a match that also matches to the edge
            %it is on, assume the dispairty of it is the same as the last
            %matched pixel
            else
                if x_~=x && x_~=0
                    d(y,x,:)=d(y_,x_,:);
                end
            end
        end
        
        
        %if the first pixel in the list doesnt have a match that is also a
        %match to the edge it is on, the top set of pixels will be empty,
        %thus, following, that is the dispairity of the first pixel that
        %had corresponding matches will be assigned to those skipped edges
        if clist(1,1)~=first_x
            j=1;
            while x~=first_x
                x=clist(j,1);
                y=clist(j,2);
                d(y,x,:)=d(first_y,first_x,:);
                j=j+1;
            end
        end
    end
    
end
display(r_matches{1,1});
end
