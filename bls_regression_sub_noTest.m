function [Y_hat,all_index,NumFea_hat,NumWin_hat,NumEnhan_hat] = ...
    bls_regression_sub_noTest(train_x,train_y,Fea_vec,Win_vec,...
    Enhan_vec,validation_x,Vp_true,den_true,f,modes_num_vec,index_vec,index_vec_all,mean_y,std_y,validation_x_norm)
% function purpose: BLS regression for Rayleigh wave inversion
%   Grid-search wrapper for BLS hyperparameter tuning (baseline version).
%   Searches over (NumFea, NumWin, NumEnhan) and selects the combination
%   that minimises the dispersion-domain validation error.
%
%   ** Baseline version **  Inputs are standard: single validation sample,
%   no importance vector, no matrix test input.
%   Compare with:
%     _importance         -- adds importance_vector output from the trained BLS
%     _matrixTestInput    -- validation_x is a matrix of multiple samples
% Inputs:
%   train_x            - (Ntrain x P) Dispersion curves, training set
%   train_y            - (Ntrain x Q) Earth-model params [h, Vs], training set
%   Fea_vec            - Search range for feature nodes per window, e.g. 1:10
%   Win_vec            - Search range for number of windows,          e.g. 1:20
%   Enhan_vec          - Search range for enhancement nodes,          e.g. 1:40
%   validation_x       - (1 x P) Observed dispersion curve,
%                        used for forward-modelling error evaluation
%   Vp_true            - Fixed P-wave velocity profile
%   den_true           - Fixed density profile
%   f                  - Frequency vector
%   modes_num_vec      - Mode index vector, e.g. [1 2 3 4]
%   mean_y, std_y      - Normalisation statistics of train_y (for rescaling)
%   validation_x_norm  - (1 x P) Normalised version of validation_x
%
% Outputs:
%   Y_hat       - Predicted earth-model parameters for the optimal BLS
%   all_index   - (MAXGEN x 2) [elapsed_time, validation_error] per trial
%   NumFea_hat  - Optimal number of feature nodes per window
%   NumWin_hat  - Optimal number of windows
%   NumEnhan_hat- Optimal number of enhancement nodes
%
% note: constructed based on author's code 
% reference:https://broadlearning.ai/download_code/
%
% Chen and Liu 2018: Chen, C. P., & Liu, Z. (2018). Broad learning system: 
%                    An effective and efficient incremental learning system
%                    without the need for deep architecture. IEEE 
%                    transactions on neural networks and learning systems, 
%                    29(1), 10-24.
%
% Chen et al. 2019: Chen, C. P., Liu, Z., & Feng, S. (2019). Universal 
%                   approximation capability of broad learning system and 
%                   its structural variations. IEEE transactions on neural 
%                   networks and learning systems, 30(4), 1191-1204.
%
assert(isfloat(train_x), 'train_x must be a float');

%% training
C = 2^-30;  %----C: the regularization parameter for sparse regualarization
s = .8;          %----s: the shrinkage parameter for enhancement nodes

%% Grid search over (NumFea, NumWin, NumEnhan)
result = [];
MAXGEN = length(Fea_vec)*length(Win_vec)*length(Enhan_vec);
time_index = zeros(MAXGEN,1);
Obj_index = zeros(MAXGEN,1);
Gen = 0;
for Num_i= 1:1:length(Fea_vec) %e.g.,1:20
    for Num_j=1:1:length(Win_vec) %e.g.,1:30
        for Num_k=1:1:length(Enhan_vec) %e.g.,1:40
            NumFea = Fea_vec(Num_i);
            NumWin = Win_vec(Num_j);
            NumEnhan = Enhan_vec(Num_k);
            % Initialise random feature-layer weights
            rand('state',1)
            for i=1:NumWin
                WeightFea=2*rand(size(train_x,2)+1,NumFea)-1;
                WF{i}=WeightFea;
            end
            WeightEnhan=2*rand(NumWin*NumFea+1,NumEnhan)-1;
            % Train BLS and evaluate on validation set
            [NetoutValidation,test_error_Y] = bls_train_noTest(train_x,...
                train_y,validation_x,WF,WeightEnhan,s,C,NumFea,NumWin,...
                Vp_true,den_true,f,modes_num_vec,index_vec,index_vec_all,...
                mean_y,std_y,validation_x_norm);

            result = [result; NumFea NumWin NumEnhan test_error_Y ...
                NetoutValidation]; % recording all the searching reaults
            
            [Y,I] = min(result(:,4));
            optimal_value = result(I,5:end);
            Obj_index(Gen+1) = Y;
            time_index(Gen+1) = toc;
            Gen = Gen+1;
        end
    end
end
all_index = [time_index Obj_index];
%% Extract optimal hyperparameters and prediction
temp_index = find(result(:,4)==min(result(:,4)));
NumFea_hat = result(temp_index,1);
NumWin_hat = result(temp_index,2);
NumEnhan_hat = result(temp_index,3);

Y_hat = result(temp_index,5:end);

end

