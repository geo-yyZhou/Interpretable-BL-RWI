function [samples_x,samples_y] = getSamples_RW_fieldData( samples_N,...
    modes_num_vec,index_vec_all,f_vector,Vp_true,den_true,Vs_profile_lower,Vs_profile_upper,dispersions_R_true)
%   Generate random earth-model samples and their corresponding multi-mode
%   Rayleigh-wave phase-velocity dispersion curves for training / testing a
%   neural-network inversion model.
%
%   For each accepted sample the function draws layer thicknesses and Vs
%   values uniformly from [Vs_profile_lower, Vs_profile_upper], computes
%   the forward dispersion response with gpdc, and stores the result.
%   Samples whose gpdc call throws an error are silently discarded and
%   redrawn until samples_N valid realisations are collected.
%
% Syntax:
%   [samples_x, samples_y] = getSamples_RW_fieldData_sub_2( ...
%       samples_N, modes_num_vec, index_vec_all, f_vector, ...
%       Vp_true, den_true, Vs_profile_lower, Vs_profile_upper, ...
%       dispersions_R_true)
%
% Inputs:
%   samples_N         - Scalar. Total number of valid samples to generate.
%   modes_num_vec     - Vector of mode indices to include (1-based; max 5).
%                       e.g. [1 2] requests the fundamental and 1st higher
%                       mode.
%   index_vec_all     - Cell array. index_vec_all{m} = [start_pt, end_pt]
%                       gives the frequency-point range for mode m within
%                       the gpdc output.
%   f_vector          - Frequency vector [Hz], e.g. 1:1:100.
%   Vp_true           - ((N+1) x 1) Fixed P-wave velocity of each layer
%                       [m/s], including the half-space.
%   den_true          - ((N+1) x 1) Fixed density of each layer [kg/m?],
%                       including the half-space.
%   Vs_profile_lower  - Row vector [h_lower, Vs_lower]: lower bounds on
%                       layer thicknesses (first N entries) and Vs (last
%                       N+1 entries).
%   Vs_profile_upper  - Row vector [h_upper, Vs_upper]: upper bounds,
%                       same layout as Vs_profile_lower.
%   dispersions_R_true- Reference dispersion vector used only to determine
%                       the expected output length of X_raw (number of
%                       frequency-mode data points).
%
% Outputs:
%   samples_x - (samples_N x P) Matrix of forward-modelled dispersion
%               curves [m/s]. P = total number of selected frequency-mode
%               points across all requested modes.
%   samples_y - (samples_N x num_unknown) Matrix of sampled earth-model
%               parameters [h (m) and Vs (m/s)].
%
% Notes:
%   - Vp and density are held fixed at their true values; only layer
%     thicknesses and Vs are randomised.
%   - gpdc is expected to return slowness (s/m) in columns 2:end; the
%     function converts to phase velocity via element-wise reciprocal.
%   - NaN entries in the computed dispersion (caused by missing higher
%     modes) are replaced with 0 before storage.
%   - Random seeds are re-initialised from the system clock at every call
%     to ensure independent realisations across repeated runs.
%

% Re-seed random number generators from the system clock
% This ensures different sample sets across repeated function calls.
rand('seed',sum(100*clock))
randn('seed',sum(100*clock))

% Input validation
assert(size(modes_num_vec,1)==1 || size(modes_num_vec,2)==1,'Error! modes_num_vec should be a vector!')
assert(max(modes_num_vec)<=5,'Error! the maximum of modes_num_vec should be no larger than 5!')

%% Ensure bound vectors are row vectors
Vs_profile_lower = Vs_profile_lower(:)';
Vs_profile_upper = Vs_profile_upper(:)';

%% Initialise sampling arrays
% Convenience aliases for the parameter bounds
x_low = Vs_profile_lower;
x_up = Vs_profile_upper;
% samples of 1st generation
num_unknown = length(x_low); % number of free parameters (h + Vs)
N_true = length(Vp_true) - 1; % number of layers (excluding half-space)

Y_raw = zeros(samples_N,num_unknown); % earth-model parameter dataset
X_raw = zeros(samples_N,length(dispersions_R_true)); % dispersion curve dataset

%% Main sampling loop (rejection-based: discard gpdc failures)
i = 1;
while i <= samples_N
    % Draw one random earth model uniformly within the prior bound
    for j = 1:num_unknown
        Y_raw(i,j) = x_low(j) + (x_up(j)-x_low(j))*rand(1,1);
    end
    % Assemble the layer model for gpdc
    h = [Y_raw(i,1:N_true) 0];
    Vp = Vp_true;
    Vs = Y_raw(i,N_true+1:2*N_true+1);
    den = den_true;
    
    model_dispersion_R = [];
    
    try
        % Forward dispersion computation
        out = gpdc(h,Vp,Vs,den,'fV',f_vector);
        out2 = rdivide(1, out(:, 2:end));
        % Extract requested modes and frequency sub-ranges
        for jj = 1:1:length(modes_num_vec)
            temp = modes_num_vec(jj);
            point_temp = index_vec_all{temp};
            star_point = point_temp(1);
            end_point = point_temp(2);
            % Append the selected frequency segment of this mode (as a row)
            model_dispersion_R = [model_dispersion_R out2(star_point:end_point,temp)'];
        end
        % Replace NaN (missing higher-mode energy) with 0
        model_dispersion_R(isnan(model_dispersion_R)) = 0;
        X_raw(i,:) = model_dispersion_R;
        
        i = i+1; % advance counter only on success
    catch
        % gpdc failed for this model (e.g. numerical instability);
        % discard and resample by not incrementing i.
    end
    
end
%% Package outputs
samples_x = X_raw;
samples_y = Y_raw;

end

