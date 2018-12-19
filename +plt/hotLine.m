
function hotLine(x,y,z,c,w,m)

if size(x,2) == 1
    x = x';
end
if size(y,2) == 1
    y = y';
end
if size(z,2) == 1
    z = z';
end
if size(c,2) == 1
    c = c';
end

if ~exist('w','var')
    w = 8;
end
if ~exist('m','var')
    m = colormap('jet');
end

surface(repmat(x,2,1),repmat(y,2,1),repmat(z,2,1),repmat(c,2,1),...
    'facecol','no',...
    'edgecol','interp',...
    'linew',w);
colorbar
colormap(gca,m);