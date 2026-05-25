function [Y_hat,all_index,NumFea_hat,NumWin_hat,NumEnhan_hat] = ...
    bls_regression_sub_noTest_matrixTestInput(train_x,train_y,Fea_vec,Win_vec,...
    Enhan_vec,validation_x,Vp_true,den_true,f,modes_num_vec,index_vec,index_vec_all,mean_y,std_y,validation_x_norm)
%   Grid-search wrapper for BLS hyperparameter tuning (matrix input version).
%   Identical to bls_regression_sub_noTest, except:
%
%   ** Differences from baseline (_noTest) **
%     1. validation_x_norm is a MATRIX (M x P) of multiple validation
%        samples, rather than a single row vector.
%     2. NetoutValidation (M x Q matrix) is NOT appended into result;
%        result stores only [NumFea, NumWin, NumEnhan, test_error_Y].
%     3. Y_hat is taken directly from the last NetoutValidation of the
%        optimal trial, not extracted from result columns 5:end.
%     4. test_error_Y is set to 0 inside bls_train_noTest_matrixTestInput
%        (forward-modelling error disabled for matrix input ¡ª see train fn).
%
% Inputs / Outputs: identical to baseline (no extra arguments).
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

%% BLS hyperparameters (fixed)
C = 2^-30;      %----C: the regularization parameter for sparse regualarization
s = .8;              %----s: the shrinkage parameter for enhancement nodes

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
            
            rand('state',1)
            for i=1:NumWin
                WeightFea=2*rand(size(train_x,2)+1,NumFea)-1;
                WF{i}=WeightFea;
            end
            WeightEnhan=2*rand(NumWin*NumFea+1,NumEnhan)-1;
            [NetoutValidation,test_error_Y] = ...
                bls_train_noTest_matrixTestInput(train_x,train_y,...
                validation_x,WF,WeightEnhan,s,C,NumFea,NumWin,Vp_true,...
                den_true,f,modes_num_vec,index_vec,index_vec_all,mean_y,...
                std_y,validation_x_norm);
            
            % ** Difference from baseline **: NetoutValidation is a matrix
            % and is NOT stored in result (would inflate row width);
            % only the 4 scalar hyperparameter/error columns are kept.
            result = [result; NumFea NumWin NumEnhan test_error_Y];
            
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

% ** Difference from baseline **: Y_hat comes from the last
% NetoutValidation in memory (matrix output), not result columns 5:end.
Y_hat = NetoutValidation;

end

