function borehole_Vs = cal_boreholeVs(h_hat,Vs_hat,h_00,dh)
% cal_boreholeVs  Interpolate a layered Vs profile onto a uniform depth grid.
%
% Syntax:
%   borehole_Vs = cal_boreholeVs(h_hat, Vs_hat, h_00, dh)
%
% Description:
%   Converts a 1-D shear-wave velocity (Vs) model defined by layer
%   thicknesses into a staircase depth-Vs profile, then resamples it onto
%   the query depth vector h_00 using linear interpolation.
%
% Inputs (n layers):
%   h_hat  - (1*n) Layer thickness vector.
%   Vs_hat - (1*(n+1)) Vs vector.
%   h_00   - (m x 1) Query depth vector on which Vs is evaluated [m].
%   dh     - Scalar depth offset used to create staircase discontinuities
%            at layer interfaces. Should be much smaller than the
%            minimum layer thickness.
%
% Output:
%   borehole_Vs - (m x 1) Vs values interpolated at depths h_00 [m/s].
%


% Cumulative depth to each layer interface
n = length(h_hat);
cumsum_h = cumsum(h_hat);

% Build the staircase depth axis (borehole_1)
borehole_1 = zeros(2*n + 2, 1);
borehole_1(1) = 0;

% Each h value is repeated twice to match the paired depth entries,
% producing a piecewise-constant (staircase) depth vector.
for i = 1:n
    borehole_1(2*i) = cumsum_h(i);
    borehole_1(2*i + 1) = cumsum_h(i) + dh;
end
borehole_1(end) = max(h_00);

% Build the corresponding Vs axis (borehole_2)
borehole_2 = zeros(2*(n+1), 1);

% Each Vs value is repeated twice to match the paired depth entries,
% producing a piecewise-constant (staircase) Vs-depth vector.
for i = 1:n+1
    borehole_2(2*i - 1) = Vs_hat(i);
    borehole_2(2*i) = Vs_hat(i);
end

% Resample the staircase profile onto the query depth grid
borehole_Vs = interp1(borehole_1, borehole_2, h_00);
end

