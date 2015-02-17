function viewer3D(img3d,meta)
% Viewer3D(img3d,meta)
%   view a 3d image
%   img3D - 3d image
%   meta - structure with fields:
%     xthickness
%     ythickness
%     zthickness
%
%  Greg Freeman
%  Jan 2015
%
%
% Derived from 
% dcm3DViewer.m
%Author: Eric Johnston
%email: ejohnst@stanford.edu
%Release: 1.2
%Date: July 31, 2010

xthickness=meta.xthickness;
ythickness=meta.ythickness;
zthickness=meta.zthickness;

%Initialize GUI
f = figure('Visible','off','Position',[0,0,1200,650],'MenuBar','none');
movegui(f,'center');
backgroundcolor = [0.95 0.95 0.95]; %Background of figure

if isfield(meta,'name')
    figname=sprintf('Interactive 3D Viewer:%s',meta.name);
else
    figname='Interactive 3D Viewer';
end

set(f,'Name',figname,'Color',backgroundcolor);
colormap('Gray'); %Dealing only with grayscaled images (*.DCM)

%Variables
typestring = ''; %Records when numbered keys are pressed
axvert = NaN; axhorz = NaN; sagvert = NaN; saghorz = NaN; corvert = NaN; corhorz = NaN; %For zooming functionality
x2 = NaN; y2 = NaN; %Current Mouse position when depressed

%Three axes handles
axial = axes('Position',[0.02 0.1 0.3 0.9],'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'Box','on');
sagittal = axes('Position',[0.35 0.1 0.3 0.9],'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'Box','on');
coronal = axes('Position',[0.68 0.1 0.3 0.9],'DataAspectRatio',[1 1 1],'XTick',[],'YTick',[],'Box','on');
axialImage=[];
sagittalImage=[];
coronalImage=[];

%uicontrols
%uicontrol('Style','PushButton','Position',[10 10 100 50],'String','Find Directory','CallBack',@lookfordicom);
zoomer = uicontrol('Style','PushButton','Position',[120 10 100 50],'String','Zoom','FontSize',13,'Enable','off','CallBack',@zoom_in);
measurer = uicontrol('Style','PushButton','Position',[230 10 100 50],'String','Measure','FontSize',13,'Enable','off','CallBack',@measure_tool);
maximize = uicontrol('Style','PushButton','Position',[340 10 100 50],'String','Maximize','FontSize',13,'Enable','off','CallBack',@max_or_min);
uicontrol('Style','Text','Position',[335+220 32 100 30],'String','Contrast:','FontSize',13,'BackgroundColor',backgroundcolor);
axtext = uicontrol('Style','Text','Position',[740+220 60 140 25],'String','Axial:','FontSize',13,'HorizontalAlignment','left','BackgroundColor',backgroundcolor);
sagtext = uicontrol('Style','Text','Position',[740+220 35 140 25],'String','Sagittal:','FontSize',13,'HorizontalAlignment','left','BackgroundColor',backgroundcolor);
cortext = uicontrol('Style','Text','Position',[740+220 10 140 25],'String','Coronal:','FontSize',13,'HorizontalAlignment','left','BackgroundColor',backgroundcolor);
contrast = uicontrol('Style','Edit','Position',[420+220 38 40 24],'String',0.5,'FontSize',13,'Enable','off','BackgroundColor',backgroundcolor,'CallBack',@contrast_edit);
slide = uicontrol('Style','Slider','Position',[340+220 10 390 25],'Value',0.5,'Enable','off','CallBack',@slide_move);
export = uicontrol('Style','PushButton','Position',[450 10 100 50],'String','Export','FontSize',13,'Enable','off','CallBack',@exportfigure);

[P, Q, R] = size(img3d);
axvert = 1:P; sagvert = 1:P; corvert = 1:Q;
axhorz = 1:Q; saghorz = 1:R; corhorz = 1:R;
curx = ceil(P/2); cury = ceil(Q/2); curz = ceil(R/2);
set(axtext,'String',['Axial: ' num2str(curz) '/' num2str(R)]);
set(sagtext,'String',['Sagittal: ' num2str(cury) '/' num2str(Q)]);
set(cortext,'String',['Coronal: ' num2str(curx) '/' num2str(P)]);
dispIm(curx,cury,curz);
set(f, 'Pointer', 'arrow');
set([zoomer measurer maximize contrast slide export],'Enable','on');
%Press Buttons
set(f,'KeyPressFcn',@(h_obj,evt) keymove(evt.Key));
set(f,'WindowScrollWheelFcn',@(h_obj,evt) keymove(evt.VerticalScrollCount));

%Make the GUI visible
set(f,'Visible','On');

%Callbacks and subfunctions
function dispIm(x,y,z) %Update all three images
    dispAxial(z);
    dispSagittal(y);
    dispCoronal(x);
end

function dispAxial(z) %Update axial image
    contrastVal=get(slide,'Value');
    set(f,'CurrentAxes',axial);
    im = double(squeeze(img3d(axvert,axhorz,z)));
    im = imadjust(im/max(im(:)),[0 1],[0 1],2*(1-contrastVal));
    axialImage=imshow(im); axis square;
    hold on
    plot([1 P P 1 1],[1 1 Q Q 1],'b')
    plot([1,Q],[curx,curx],'r')
    plot([cury,cury],[1,P],'g')
    hold off
    set(axialImage,    'ButtonDownFcn',@(h , eventData ) ImageClickCallback(h,'axial')    );
end

function dispSagittal(y) %Updata sagittal image
    set(f,'CurrentAxes',sagittal);
    im = double(squeeze(img3d(sagvert,y,saghorz)));
    im = imadjust(im.'/max(im(:)),[0 1],[0 1],2*(1-get(slide,'Value')));
    sagittalImage=imshow(im); axis square;
    hold on
    plot([1 P P 1 1],[1 1 R R 1],'g')
    plot([curx,curx],[1,R],'r')
    plot([1,Q],[curz,curz],'b')
    hold off
    set(sagittalImage,    'ButtonDownFcn',@(h , eventData ) ImageClickCallback(h,'sagittal')    );

end

function dispCoronal(x) %Update coronal image
    set(f,'CurrentAxes',coronal);
    im = double(squeeze(img3d(x,corvert,corhorz)));
    im = imadjust(im.'/max(im(:)),[0 1],[0 1],2*(1-get(slide,'Value')));
    coronalImage=imshow(im); axis square;
    hold on
    plot([1 Q Q 1 1],[1 1 R R 1],'r')
    plot([cury,cury],[1,R],'g')
    plot([1,Q],[curz,curz],'b')
    hold off
    set(coronalImage,    'ButtonDownFcn',@(h , eventData ) ImageClickCallback(h,'coronal')    );

end

function keymove(key)
    if strcmp(key,'uparrow') || sum(key)==-1 %If the uparrow is pressed or the mouse wheel is turned
        if (gca == axial && curz<R) %And we're not out of bounds
            curz = curz+1; 
            dispIm(curx,cury,curz); 
            set(f,'CurrentAxes',axial); 
            set(axtext,'String',['Axial: ' num2str(curz) '/' num2str(R)]);
        elseif (gca == sagittal && cury<P)
            cury = cury+1; 
            dispIm(curx,cury,curz); 
            set(f,'CurrentAxes',sagittal); 
            set(sagtext,'String',['Sagittal: ' num2str(cury) '/' num2str(Q)]);
        elseif (gca == coronal && curx<Q)
            curx = curx+1; 
            dispIm(curx,cury,curz); 
            set(f,'CurrentAxes',coronal); 
            set(cortext,'String',['Coronal: ' num2str(curx) '/' num2str(P)]);
        end
    elseif strcmp(key,'downarrow') || sum(key)==1 %If the down arrow or mouse wheel is turned
        if (gca == axial && curz>1) %And we're not out of bounds
            curz = curz-1; 
            dispIm(curx,cury,curz); 
            set(f,'CurrentAxes',axial); 
            set(axtext,'String',['Axial: ' num2str(curz) '/' num2str(R)]);
        elseif (gca == sagittal && cury>1)
            cury = cury-1; 
            dispIm(curx,cury,curz); 
            set(f,'CurrentAxes',sagittal); 
            set(sagtext,'String',['Sagittal: ' num2str(cury) '/' num2str(Q)]);
        elseif (gca == coronal && curx>1)
            curx = curx-1; 
            dispIm(curx,cury,curz); 
            set(f,'CurrentAxes',coronal); 
            set(cortext,'String',['Coronal: ' num2str(curx) '/' num2str(P)]);
        end
    elseif sum(strcmp(key,{'1','2','3','4','5','6','7','8','9','0'})) && length(typestring)<4 %If a numbered key is pressed and not too 
        typestring = strcat(typestring,key); %Add the number to the string typed              %many have already been pressed
        if (gca == axial), set(axtext,'String',['Axial: ' typestring '/' num2str(R)]);
        elseif (gca == sagittal), set(sagtext,'String',['Sagittal: ' typestring '/' num2str(Q)]);
        elseif (gca == coronal), set(cortext,'String',['Coronal: ' typestring '/' num2str(P)]);
        end
    elseif strcmp(key,'return') && ~isempty(typestring) %If a return is pressed then update the current cross section
        if (gca == axial)
            curz = round(str2double(typestring));
            if curz>R, curz=R;
            elseif curz<1, curz=1;   
            end
            set(axtext,'String',['Axial: ' num2str(curz) '/' num2str(R)]);
            dispIm(curx,cury,curz);
        elseif (gca == sagittal)
            cury = round(str2double(typestring));
            if cury>P, cury=P;
            elseif cury<1, cury=1;   
            end
            set(sagtext,'String',['Sagittal: ' num2str(cury) '/' num2str(Q)]);
            dispIm(curx,cury,curz);
        elseif (gca == coronal)
            curx = round(str2double(typestring));
            if curx>Q, curx=Q;
            elseif curx<1, curx=1;   
            end
            set(cortext,'String',['Coronal: ' num2str(curx) '/' num2str(P)]);
            dispIm(curx,cury,curz);
        end
        typestring = '';
    else %If the wrong key was pressed act is if no button had ever been pressed
        typestring = '';
        if (gca == axial), set(axtext,'String',['Axial: ' num2str(curz) '/' num2str(R)]);
        elseif (gca == sagittal), set(sagtext,'String',['Sagittal: ' num2str(cury) '/' num2str(Q)]);
        elseif (gca == coronal), set(cortext,'String',['Coronal: ' num2str(curx) '/' num2str(P)]);
        end
    end
end

function ImageClickCallback ( objectHandle , name )
    axesHandle  = get(objectHandle,'Parent');
    coordinates = get(axesHandle,'CurrentPoint'); 
    coordinates = coordinates(1,1:2);
    switch name
        case 'axial'
            curx=floor(coordinates(2));
            cury=floor(coordinates(1));
            dispIm(curx,cury,curz); 
            set(cortext,'String',['Coronal: ' num2str(curx) '/' num2str(P)]);
            set(sagtext,'String',['Sagittal: ' num2str(cury) '/' num2str(Q)]);
            set(f,'CurrentAxes',axial); 
        case 'sagittal'
            curx=floor(coordinates(1));
            curz=floor(coordinates(2));
            dispIm(curx,cury,curz); 
            set(cortext,'String',['Coronal: ' num2str(curx) '/' num2str(P)]);
            set(axtext,'String',['Axial: ' num2str(curz) '/' num2str(R)]);       
            set(f,'CurrentAxes',sagittal);
        case 'coronal'
            cury=floor(coordinates(1));
            curz=floor(coordinates(2));
            dispIm(curx,cury,curz); 
            set(sagtext,'String',['Sagittal: ' num2str(cury) '/' num2str(Q)]);
            set(axtext,'String',['Axial: ' num2str(curz) '/' num2str(R)]);         
            set(f,'CurrentAxes',coronal);
    end

end

function slide_move(src,eventdata) %#ok<INUSD> %If the slider moves change the label
    set(contrast,'String',round(100*get(slide,'Value'))/100);
    dispIm(curx,cury,curz); %Update all images
end

function exportfigure(src,eventdata) %#ok<INUSD>
    if (gca==axial)
        figure('Position',[552 86 676 598],'Visible','off'); movegui(gcf,'center'); set(gcf,'Visible','on');
        set(gca,'DataAspectRatio',[1 1 1],'Position',[0.1212 0.0936 0.7574 0.8562],'XTick',[],'YTick',[],'Box','on');
        im = double(squeeze(img3d(axvert,axhorz,curz)));
        im = imadjust(im/max(im(:)),[0 1],[0 1],2*(1-get(slide,'Value')));
        imshow(im); axis square;
    elseif (gca==sagittal)
        figure('Position',[552 86 676 598],'Visible','off'); movegui(gcf,'center'); set(gcf,'Visible','on');
        set(gca,'DataAspectRatio',[1 1 1],'Position',[0.1212 0.0936 0.7574 0.8562],'XTick',[],'YTick',[],'Box','on');
        im = double(squeeze(img3d(sagvert,cury,saghorz)));
        im = imadjust(im.'/max(im(:)),[0 1],[0 1],2*(1-get(slide,'Value')));
        imshow(im); axis square;
    elseif (gca==coronal)
        figure('Position',[552 86 676 598],'Visible','off'); movegui(gcf,'center'); set(gcf,'Visible','on');
        set(gca,'DataAspectRatio',[1 1 1],'Position',[0.1212 0.0936 0.7574 0.8562],'XTick',[],'YTick',[],'Box','on');
        im = double(squeeze(img3d(curx,corvert,corhorz)));
        im = imadjust(im.'/max(im(:)),[0 1],[0 1],2*(1-get(slide,'Value')));
        imshow(im); axis square;
    end
end

function contrast_edit(src,eventdata) %#ok<INUSD> %If a value is typed fix the slider
    value = str2double(get(contrast,'String'));
    if value>1, set(slide,'Value',1); set(contrast,'String',num2str(1));
    elseif value<0, set(slide,'Value',0); set(contrast,'String',num2str(0));
    elseif value>0 && value<1, set(slide,'Value',value);
    else set(slide,'Value',0.5); set(contrast,'String',num2str(0.5));
    end
    dispIm(curx,cury,curz); %Update all images
end

function zoom_in(src,eventdata) %#ok<INUSD>
    set(f,'Pointer','crosshair');
    try
        waitforbuttonpress; %Wait to see where the user clicks
    catch %#ok<CTCH>
        return
    end
    d = get(gca,'CurrentPoint');
    x1 = d(1,1); y1 = d(1,2); %Set as the anchor x,y coordinates
    if (gca == axial)
        if x1>0 && x1<length(axhorz) && y1>0 && y1<length(axvert)
            a = rectangle('Position',[x1 y1 eps eps],'EdgeColor','Red');
            set(f,'WindowButtonMotionFcn',@(h_obj,evt) zoomdrag(a,x1,y1,1));
            set(f,'WindowButtonUpFcn',@(h_obj,evt) stopdrag(a,x1,y1));
        end
    elseif (gca == sagittal)
        if x1>0 && x1<length(sagvert) && y1>0 && y1<length(saghorz)
            a = rectangle('Position',[x1 y1 eps eps],'EdgeColor','Red');
            set(f,'WindowButtonMotionFcn',@(h_obj,evt) zoomdrag(a,x1,y1,2));
            set(f,'WindowButtonUpFcn',@(h_obj,evt) stopdrag(a,x1,y1));
        end
    elseif (gca == coronal)
        if x1>0 && x1<length(corvert) && y1>0 && y1<length(corhorz)
            a = rectangle('Position',[x1 y1 eps eps],'EdgeColor','Red');
            set(f,'WindowButtonMotionFcn',@(h_obj,evt) zoomdrag(a,x1,y1,3));
            set(f,'WindowButtonUpFcn',@(h_obj,evt) stopdrag(a,x1,y1));
        end
    end
    set(f,'Pointer','arrow');
end

function zoomdrag(a,x1,y1,axestype) %Track the second point
    set(f,'Pointer','crosshair');
    data = get(gca,'CurrentPoint');
    x2 = data(1,1); y2 = data(1,2);
    if x2<1, x2=1; elseif y2<1, y2=1; end
    switch axestype %Always make a rectangle no matter where the second point is
        case 1, if x2>length(axhorz), x2=length(axhorz); end, if y2>length(axvert), y2=length(axvert); end
        case 2, if x2>length(sagvert), x2=length(sagvert); end, if y2>length(saghorz), y2=length(saghorz); end
        case 3, if x2>length(corvert), x2=length(corvert); end, if y2>length(corhorz), y2=length(corhorz); end
    end
    if x2>x1 && y2>y1
        set(a,'Position',[x1 y1 x2-x1 y2-y1]);
    elseif x2>x1 && y2<y1
        set(a,'Position',[x1 y2 x2-x1 y1-y2]);
    elseif x2<x1 && y2>y1
        set(a,'Position',[x2 y1 x1-x2 y2-y1]);
    elseif x2<x1 && y2<y1
        set(a,'Position',[x2 y2 x1-x2 y1-y2]);
    end
end

function stopdrag(a,x1,y1) %When the user stops dragging, zoom in on the area enclosed by the box
    set(f,'WindowButtonMotionFcn','','WindowButtonUpFcn','','Pointer','arrow');
    delete(a);
    if (gca == axial)
        if (x2<x1 && y2<y1) || abs(x2-x1)<2 || abs(y2-y1)<2
           axhorz = 1:P; axvert = 1:Q; dispAxial(curz);
        elseif x2<x1 && y1<y2
           axhorz = (axhorz(1)-1) + (ceil(x2):floor(x1)); axvert = (axvert(1)-1) + (ceil(y1):floor(y2)); dispAxial(curz);
        elseif x1<x2 && y2<y1
           axhorz = (axhorz(1)-1) + (ceil(x1):floor(x2)); axvert = (axvert(1)-1) + (ceil(y2):floor(y1)); dispAxial(curz);
        elseif x1<x2 && y1<y2
           axhorz = (axhorz(1)-1) + (ceil(x1):floor(x2)); axvert = (axvert(1)-1) + (ceil(y1):floor(y2)); dispAxial(curz);
        end
    elseif (gca == sagittal)
        if (x2<x1 && y2<y1) || abs(x2-x1)<2 || abs(y2-y1)<2
           sagvert = 1:P; saghorz = 1:R; dispSagittal(cury);
        elseif x2<x1 && y1<y2
           sagvert = (sagvert(1)-1) + (ceil(x2):floor(x1)); saghorz = (saghorz(1)-1) + (ceil(y1):floor(y2)); dispSagittal(cury);
        elseif x1<x2 && y2<y1
           sagvert = (sagvert(1)-1) + (ceil(x1):floor(x2)); saghorz = (saghorz(1)-1) + (ceil(y2):floor(y1)); dispSagittal(cury);
        elseif x1<x2 && y1<y2
           sagvert = (sagvert(1)-1) + (ceil(x1):floor(x2)); saghorz = (saghorz(1)-1) + (ceil(y1):floor(y2)); dispSagittal(cury);
        end
    elseif (gca == coronal)
        if (x2<x1 && y2<y1) || abs(x2-x1)<2 || abs(y2-y1)<2
           corvert = 1:Q; corhorz = 1:R; dispCoronal(curx);
        elseif x2<x1 && y1<y2
           corvert = (corvert(1)-1) + (ceil(x2):floor(x1)); corhorz = (corhorz(1)-1) + (ceil(y1):floor(y2)); dispCoronal(curx);
        elseif x1<x2 && y2<y1
           corvert = (corvert(1)-1) + (ceil(x1):floor(x2)); corhorz = (corhorz(1)-1) + (ceil(y2):floor(y1)); dispCoronal(curx);
        elseif x1<x2 && y1<y2
           corvert = (corvert(1)-1) + (ceil(x1):floor(x2)); corhorz = (corhorz(1)-1) + (ceil(y1):floor(y2)); dispCoronal(curx);
        end
    end
end

function measure_tool(src,eventdata) %#ok<INUSD> %Measures the distance between points
     set(f,'Pointer','crosshair');
     try
        waitforbuttonpress; %Wait to see where the user clicks
     catch %#ok<CTCH>
         return
     end
     d = get(gca,'CurrentPoint');
     x1 = d(1,1); y1 = d(1,2); %Get the anchor point
     if (gca == axial)
         if x1>0 && x1<length(axhorz) && y1>0 && y1<length(axvert)
            a = line([x1 x1], [y1 y1],'Color','Green');
            t = uicontrol('Style','text','String','','ForegroundColor','Green','BackgroundColor','Black','Position',[x1 y1 1 1],'Visible','off');
            set(f,'WindowButtonMotionFcn',@(h_obj,evt) measuredrag(a,t,x1,y1,1));
            set(f,'WindowButtonUpFcn',@(h_obj,evt) measurestop(a,t));
         end
     elseif (gca == sagittal)
         if x1>0 && x1<length(sagvert) && y1>0 && y1<length(saghorz)
            a = line([x1 x1], [y1 y1],'Color','Green');
            t = uicontrol('Style','text','String','','ForegroundColor','Green','BackgroundColor','Black','Position',[x1 y1 1 1],'Visible','off');
            set(f,'WindowButtonMotionFcn',@(h_obj,evt) measuredrag(a,t,x1,y1,2));
            set(f,'WindowButtonUpFcn',@(h_obj,evt) measurestop(a,t));
         end
     elseif (gca == coronal)
         if x1>0 && x1<length(corvert) && y1>0 && y1<length(corhorz)
            a = line([x1 x1], [y1 y1],'Color','Green');
            t = uicontrol('Style','text','String','','ForegroundColor','Green','BackgroundColor','Black','Position',[x1 y1 1 1],'Visible','off');
            set(f,'WindowButtonMotionFcn',@(h_obj,evt) measuredrag(a,t,x1,y1,3));
            set(f,'WindowButtonUpFcn',@(h_obj,evt) measurestop(a,t));
         end
     end
     set(f,'Pointer','arrow');
end

function measuredrag(a,t,x1,y1,axestype) %Alter the measurement when the mouse drags
     set(f,'Pointer','crosshair');
     data = get(gca,'CurrentPoint'); %Local data point used to find line length
     dataf = get(f,'CurrentPoint'); %Global figure data point used to find location of distance text
     x2 = data(1,1); y2 = data(1,2);
     if x2<1, x2=1; elseif y2<1, y2=1; end
     switch axestype
        case 1
            if x2>length(axhorz), x2=length(axhorz); end, if y2>length(axvert), y2=length(axvert); end
            set(a,'XData',[x1 x2],'YData',[y1 y2]); %Update new line data points
            distance = round(sqrt(xthickness*xthickness*(x1-x2)^2+ythickness*ythickness*(y1-y2)^2)*100)/100;
            set(t,'String',strcat(num2str(distance),'mm'),'Position',[dataf(1,1)+5 dataf(1,2)-20 60 15],'Visible','on'); %Calculate distance
        case 2
            if x2>length(sagvert), x2=length(sagvert); end, if y2>length(saghorz), y2=length(saghorz); end
            set(a,'XData',[x1 x2],'YData',[y1 y2]); %Update new line data points
            distance = round(sqrt(xthickness*xthickness*(x1-x2)^2+zthickness*zthickness*(y1-y2)^2)*100)/100;
            set(t,'String',strcat(num2str(distance),'mm'),'Position',[dataf(1,1)+5 dataf(1,2)-20 60 15],'Visible','on'); %Calculate distance
        case 3
            if x2>length(corvert), x2=length(corvert); end, if y2>length(corhorz), y2=length(corhorz); end
            set(a,'XData',[x1 x2],'YData',[y1 y2]); %Update new line data points
            distance = round(sqrt(ythickness*ythickness*(x1-x2)^2+zthickness*zthickness*(y1-y2)^2)*100)/100;
            set(t,'String',strcat(num2str(distance),'mm'),'Position',[dataf(1,1)+5 dataf(1,2)-20 60 15],'Visible','on'); %Calculate distance
     end
end

function measurestop(a,t)
     set(f,'WindowButtonMotionFcn','','WindowButtonUpFcn','','Pointer','arrow');
     try 
        waitforbuttonpress; %When a button is clicked get rid of the measurement
     catch %#ok<CTCH>
         return 
     end
     delete(a); delete(t); %Delete the line and text box showing distance
end

function max_or_min(src,eventdata) %#ok<INUSD> %Adjusts relative sizes of axes
     if strcmp(get(maximize,'String'),'Maximize')
         set(maximize,'String','Minimize');
         if (gca == axial)
             set(axial,'Position',[0.1 0.15 0.8 0.83]); axis square;
             set(sagittal,'Position',[0.01 0.35 0.25 0.4]); axis square;
             set(coronal,'Position',[0.74 0.35 0.25 0.4]); axis square;
         elseif (gca == sagittal)
             set(sagittal,'Position',[0.1 0.15 0.8 0.83]); axis square;
             set(axial,'Position',[0.01 0.35 0.25 0.4]); axis square;
             set(coronal,'Position',[0.74 0.35 0.25 0.4]); axis square;
         elseif (gca == coronal)
             set(coronal,'Position',[0.1 0.15 0.8 0.83]); axis square;
             set(axial,'Position',[0.01 0.35 0.25 0.4]); axis square;
             set(sagittal,'Position',[0.74 0.35 0.25 0.4]); axis square;
         end
     else
         set(maximize,'String','Maximize');
         set(axial,'Position',[0.02 0.1 0.3 0.9]); axis square;
         set(sagittal,'Position',[0.35 0.1 0.3 0.9]); axis square;
         set(coronal,'Position',[0.68 0.1 0.3 0.9]); axis square;
     end
end

end %GUI function end
