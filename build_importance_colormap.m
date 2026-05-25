function custom_cmap = build_importance_colormap()
% BUILD_IMPORTANCE_COLORMAP  Build a 256-entry custom colormap whose hue
%   transitions are strictly aligned to every 0.1 tick on a [0, 1] scale.
%
% Description:
%   The full [0, 1] importance range is divided into 10 equal sub-intervals.
%   Segment boundaries are computed with round(linspace(...)) to avoid
%   accumulated floating-point error, so each segment receives exactly the
%   correct number of colormap rows.  Within each segment the RGB channels
%   are linearly interpolated between two anchor colours.
%
% Output:
%   custom_cmap - (256 x 3) colormap matrix, suitable for use with
%                 colormap() and caxis([0 1]).
%
% Usage:
%   colormap(build_importance_colormap());
%   caxis([0 1]);
%

n_colors = 256;

% Compute segment boundary indices (integer, no cumulative rounding error)
edges = round(linspace(0, n_colors, 11));  % 11 edges ↙ 10 segments

% Number of colormap rows assigned to each 0.1-wide sub-interval
n  = diff(edges);   % n(1)＃n(10), sum == n_colors

% --- Per-segment linear RGB gradients ---
% Each row: linspace(R_start, R_end, n(k))  etc.
mk = @(r1,r2, g1,g2, b1,b2, k) ...
    [linspace(r1,r2,n(k))', linspace(g1,g2,n(k))', linspace(b1,b2,n(k))'];

cmap01 = mk(0.9,0.5,  0.9,0.5,  0.9,0.5,  1);  % [0.0每0.1]  light grey  ↙ grey
cmap02 = mk(1.0,1.0,  1.0,0.7,  0.8,0.0,  2);  % [0.1每0.2]  light yellow↙ deep yellow
cmap03 = mk(0.7,0.0,  1.0,0.5,  0.5,0.0,  3);  % [0.2每0.3]  light green ↙ deep green
cmap04 = mk(0.5,0.0,  1.0,0.7,  1.0,0.8,  4);  % [0.3每0.4]  light cyan  ↙ deep cyan
cmap05 = mk(0.4,0.0,  0.6,0.2,  1.0,0.8,  5);  % [0.4每0.5]  blue        ↙ deep blue
cmap06 = mk(0.7,0.4,  0.4,0.1,  0.9,0.7,  6);  % [0.5每0.6]  light purple↙ deep purple
cmap07 = mk(1.0,0.8,  0.5,0.2,  1.0,0.8,  7);  % [0.6每0.7]  light pink  ↙ deep pink
cmap08 = mk(1.0,0.8,  0.4,0.1,  0.7,0.4,  8);  % [0.7每0.8]  light rose  ↙ deep rose
cmap09 = mk(1.0,1.0,  0.5,0.27, 0.3,0.0,  9);  % [0.8每0.9]  light orange↙ orange-red
cmap10 = mk(0.7,0.4,  0.15,0.0, 0.1,0.0, 10);  % [0.9每1.0]  dark red    ↙ deep dark red

custom_cmap = [cmap01; cmap02; cmap03; cmap04; cmap05; ...
               cmap06; cmap07; cmap08; cmap09; cmap10];
end
