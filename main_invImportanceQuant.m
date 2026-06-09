% Code package purpose: Accoplish the proposed method in the paper 
%                       entitled "Interpretable Rayleigh Wave Inversion 
%                                Framework and Its Practical Implications".
% Open research: The inversion program is hosted on the author's
%    GitHub repository (https://github.com/geo-yyZhou/Interpretable-BL-RWI)
%
% Paper status: Submitted to Journal of Applied Geophysics
%
% Authors: Yuanyuan Zhou, Xiao-Hui Yang, Peng Han, Katsumi Hattori, 
%                       Ruidong Li, Bingbing Han, Wuhu Zhang, Xiaofei Chen.
%
% software version: MATLAB R2017a
%
% Acknowledgement: The forward modeling program used to generate 
%                  theoretical Rayleigh wave dispersion curves in this 
%                  code package was obtained from the  website 
%                  (https://github.com/eespr/MuLTI) provided by 
%                  Killingbeck et al. (2018); the broad learning network 
%                  codes available on the website 
%                  (https://broadlearning.ai/, Chen and Liu 2017 and Chen 
%                  et al. 2018) were also applied for the accomplishment of
%                  this code package.Additionally, the inversion package of
%                  Yang et al. (2023), particularly its sample selection 
%                  method, was employed.
%
% Killingbeck et al. (2018): Killingbeck, S. F., Livermore, P. W., 
%                            Booth, A. D., & West, L. J. (2018). Multimodal 
%                            layered transdimensional inversion of seismic 
%                            dispersion curves with depth constraints. 
%                            Geochemistry, Geophysics, Geosystems, 19(12), 
%                            4957-4971.
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
% Yang et al. 2023: Yang, X.H., Zu, Q., Zhou, Y., Han, P., & Chen, X.(2023). 
%                   A sample selection method for neural-network-based 
%                   Rayleigh wave inversion. IEEE Transactions on Geoscience
%                   and Remote Sensing, 62, 1-17.
%
% Date: 2026/05/22
%
% Study idea proposed by: Yuanyuan Zhou
%
% Code package developed by: Yuanyuan Zhou and Xiao-Hui Yang
%
% Email: zhouyy@cuit.edu.cn
%
% Code function: Perform the broad learning dispsersion curve inversion.  
%                Based on this, the proposed framework can quantitatively 
%                assess the contribution of individual phase-velocity 
%                points, thereby establishing an interpretable Rayleigh 
%                wave inversion framework.
%


clear;
clc;
close all;

rand('seed',sum(100*clock))
randn('seed',sum(100*clock))

myFontSize = 20;

%% Input dispersion data
data_0 = xlsread('uniformDis_fun.xlsx');
data_1 = xlsread('uniformDis_1st.xlsx');
data_2 = xlsread('uniformDis_2nd.xlsx');
% data_3 = xlsread('uniformDis_3rd.xls');

curve_00 = data_0;
curve_01 = data_1;
curve_02 = data_2;
% curve_03 = data_3;

f_00 = curve_00(:,1)';
dispersion_00 = curve_00(:,2)';
f_01 = curve_01(:,1)';
dispersion_01 = curve_01(:,2)';
f_02 = curve_02(:,1)';
dispersion_02 = curve_02(:,2)';
f_00_min = min(f_00); f_00_max = max(f_00);
f_01_min = min(f_01); f_01_max = max(f_01);
f_02_min = min(f_02); f_02_max = max(f_02);
df = f_00(2) - f_00(1);

dispersion_all_cell = cell(1,4);
dispersion_all_cell{1} = dispersion_00;
dispersion_all_cell{2} = dispersion_01;
dispersion_all_cell{3} = dispersion_02;
% dispersion_all_cell{4} = dispersion_03;

f = min([f_00 f_01 f_02]):df:max([f_00 f_01 f_02]);
% e.g., f = 6:df:100;
index_vec_all = cell(1,4);
index_vec_all{1} = [find(f == f_00_min) find(f == f_00_max)];
index_vec_all{2} = [find(f == f_01_min) find(f == f_01_max)];
index_vec_all{3} = [find(f == f_02_min) find(f == f_02_max)];
% index_vec_all{4} = [find(f == f_03_min) find(f == f_03_max)];

modes_num_vec = [1 2 3];
% e.g., modes_num_vec = 1;
% e.g., modes_num_vec = [1 2 3 4];
index_vec = index_vec_all(modes_num_vec);

dispersions_R_true = [];
for jj = 1:1:length(modes_num_vec)
    temp = modes_num_vec(jj);
    dispersions_R_true = [dispersions_R_true dispersion_all_cell{temp}];
end

%% numerical simulation model parameters for dispersion curves
h_true = [3 3 4];
h_true2 = [h_true 0];
Vs_true = [200 400 300 600];
Vp_true = [350 700 520 1050]; % P-wave velocity of each layer
den_true = [1.70 1.80 1.75 1.90]; % density of each layer

layers_num = length(Vp_true);

Vs_true_profile = [h_true Vs_true];

x_low = [1.5 1.5 2 80 100 150 300];
x_up = [4.5 4.5 5 420 450 550 700];

Vs_profile_lower = x_low(:)';
Vs_profile_upper = x_up(:)';

% borehole data, namely true Vs profile for numerical simulation
borehole = xlsread('Vs_profile_true.xls');

tic

%% training sample selection
train_samples_N_temp = 5000;
disp('-------------------------------------------------------------------')
disp('Waiting about two minutes for generating training sample pool ...')
% training sample pool
[train_x_temp,train_y_temp] = getSamples_RW_fieldData(...
    train_samples_N_temp,modes_num_vec,index_vec_all,f,Vp_true,den_true,...
    Vs_profile_lower,Vs_profile_upper,dispersions_R_true);
% validation datasets
validation_x = dispersions_R_true;
validation_y = borehole;

% generate training set and validation set
train_samples_N = 500; % each stage
samples_N = train_samples_N;

disp('Waiting about one minute for sample selection ...')
% ----------------------- sample selection start -------------------------
corr_vector = zeros(1,train_samples_N_temp);

% window_num = 30;
window_num = floor(0.2*length(validation_x));
corr_vector_temp = zeros(1,length(validation_x)-window_num);

for j = 1:train_samples_N_temp
    
    for i = 1:length(validation_x)-window_num
        temp = train_x_temp(j,i:i+window_num);
        if sum(abs(temp-temp(1)*ones(1,length(temp)))) == 0
            temp(1) = temp(1) + 0.1; % avoid nan
        end
        cc = corrcoef(temp,validation_x(i:i+window_num));
        
        corr_vector_temp(i) = cc(2,1);
    end
    corr_vector(j) = mean(corr_vector_temp);
    
    [corr_rank,corr_index] = sort(corr_vector,'descend');
end

train_x = train_x_temp(corr_index(1:samples_N),:);
train_y = train_y_temp(corr_index(1:samples_N),:);

selection_time = toc;
fprintf('Sample pool generation and selection: %f mins\n', selection_time/60);
% ------------------------- sample selection end -------------------------

tic
%% BLS regression for inversion - all velocity points
% Complexity selection grid
Fea_vec = 4:2:10;
Win_vec = 4:2:20;
Enhan_vec = 4:2:30;
% Normalize data (mean=0, std=1)
[mean_x,std_x,train_x_norm] = normalized_fun(train_x);
[mean_y,std_y,train_y_norm] = normalized_fun(train_y);
validation_x_norm = zeros(size(validation_x,1),size(validation_x,2));
for i = 1:1:size(validation_x,2)
    validation_x_norm(:,i) = (validation_x(:,i)-mean_x(i))/std_x(i);
end
% BLS inversion (including trainning)
disp('-------------------------------------------------------------------')
disp('Waiting about one minute for inversion of all velocity points ...')
[Y_hat,all_index,NumFea_hat,NumWin_hat,NumEnhan_hat] = ...
    bls_regression_sub_noTest(train_x_norm,train_y_norm,Fea_vec,...
    Win_vec,Enhan_vec,validation_x,Vp_true,den_true,f,modes_num_vec,...
    index_vec,index_vec_all,mean_y,std_y,validation_x_norm);
dispersions_R_inverted = calSynDispersion(Y_hat,Vp_true,den_true,f,...
    modes_num_vec,index_vec_all);

toc

disp('The inverted Vs profile for all velocity points:');
disp(Y_hat);
%% plot inverted results: all phase velocity points
% plot inverted dipsersion curves
my_linewidth = 2.5;
figure()
fig = gcf; % Get current figure
% f_plot = 1:1:100;

h2 = [Y_hat(1:3) 0];
Vs = Y_hat(4:end);

scatter(f_00, dispersion_00, 50, 'k', 'LineWidth', 0.5);
hold on
scatter(f_01, dispersion_01, 50, 'k', 'LineWidth', 0.5);
scatter(f_02, dispersion_02, 50, 'k', 'LineWidth', 0.5);
out = gpdc(h2,Vp_true,Vs,den_true,'fV',f_00);
out2 = rdivide(1, out(:, 2:end));
plot(f_00,out2(:,1)','Color',[255 0 0]/255,'LineWidth',my_linewidth);
out = gpdc(h2,Vp_true,Vs,den_true,'fV',f_01);
out2 = rdivide(1, out(:, 2:end));
plot(f_01,out2(:,2)','Color',[255 0 0]/255,'LineWidth',my_linewidth);
out = gpdc(h2,Vp_true,Vs,den_true,'fV',f_02);
out2 = rdivide(1, out(:, 2:end));
plot(f_02,out2(:,3)','Color',[255 0 0]/255,'LineWidth',my_linewidth);

box on;
axis([0 100 170 510]);
set(gca,'XTick',0:20:100);
set(gca,'YTick',100:100:700);
xlabel('Frequency [Hz]','FontSize',myFontSize);
ylabel('Phase velocity [m/s]','FontSize',myFontSize);
set(gca,'FontName','Times New Roman','FontSize',myFontSize);

% plot objective function curve
figure()
fig = gcf; % Get current figure
plot(all_index(:,1),all_index(:,2),'b','Linewidth',my_linewidth);
axis([0 40 0 15]);
xlabel('Time [s]','FontSize',myFontSize);
ylabel('Obj','FontSize',myFontSize);
set(gca,'FontName','Times New Roman','FontSize',myFontSize);

% plot inverted Vs profile
figure()
fig = gcf; % Get current figure
plot(borehole(:,2),borehole(:,1),':','Color',[150 150 150]/255,...
    'Linewidth',my_linewidth);
hold on
temp = [h_true Vs_true];
drawMultiProfile_addSS(Y_hat,temp(1:3),temp(4:end),...
    Vs_profile_lower,Vs_profile_upper,myFontSize,my_linewidth)
fig.Position = [680,100,560,460];

%% Perform importance quantification
dh = 0.01;
h_max = 15; % the value should be suitable for field data
% h_max = sum(h_true) + h_true(end); % for simulation
h_00 = 0:dh:h_max;

h_hat = Y_hat(1:layers_num-1);
Vs_hat = Y_hat(layers_num:end);
borehole_Vs_hat = cal_boreholeVs(h_hat,Vs_hat,h_00,dh);

h_00_15 = 0:dh:15;
borehole_Vs_true_15 = cal_boreholeVs(h_true,Vs_true,h_00_15,dh);
borehole_Vs_hat_15 = cal_boreholeVs(h_hat,Vs_hat,h_00_15,dh);
MAPE_Y_hat_15 = mean(abs(borehole_Vs_hat_15 - ...
    borehole_Vs_true_15)./borehole_Vs_true_15);%%

fprintf('MAPE of inverted profile for all velocity points: %f%%\n', ...
    MAPE_Y_hat_15*100);
disp('-------------------------------------------------------------------')

importance_vector = zeros(1,length(dispersions_R_true));

disLB_percent = 0.001; % 0%
disUB_percent = 2; % 200%
percentNum = 100; % number of multiple perturbed velocity samples
randPercentVector = disUB_percent * rand(1,percentNum);
importance_matrix = zeros(percentNum,length(dispersions_R_true));


for jjj = 1:length(dispersions_R_true)
    validation_x_matrix = repmat(validation_x, percentNum, 1);
    validation_x_temp = validation_x;
    for kkk = 1:percentNum
        percentTemp = randPercentVector(kkk);
        validation_x_matrix(kkk,jjj) = validation_x(jjj)*percentTemp;
    end
    validation_x_matrix_norm_temp = zeros(size(validation_x_matrix,1),size(validation_x_matrix,2));
    for i = 1:1:size(validation_x_matrix,2)
        validation_x_matrix_norm_temp(:,i) = (validation_x_matrix(:,i)-mean_x(i))/std_x(i);
    end
    [Y_hat_matrix_temp,all_index_temp,temp_1,temp_2,temp_3] = bls_regression_sub_noTest_matrixTestInput(...
        train_x_norm,train_y_norm,NumFea_hat,NumWin_hat,NumEnhan_hat,validation_x_matrix,...
        Vp_true,den_true,f,modes_num_vec,index_vec,index_vec_all,mean_y,std_y,validation_x_matrix_norm_temp);
    for kkk = 1:percentNum
        Y_hat_temp = Y_hat_matrix_temp(kkk,:);
        h_hat_temp = Y_hat_temp(1:layers_num-1);
        Vs_hat_temp = Y_hat_temp(layers_num:end);
        borehole_Vs_hat_temp = cal_boreholeVs(h_hat_temp,Vs_hat_temp,h_00,dh);
        importance_matrix(kkk,jjj) = mean(abs(borehole_Vs_hat_temp-borehole_Vs_hat)./borehole_Vs_hat);
    end
end
importance_vector = mean(importance_matrix);
importance_vector = importance_vector/max(importance_vector);

% plot importance quantification results
figure()
fig = gcf;
f_all = [f_00 f_01 f_02];
v_all = [dispersion_00 dispersion_01 dispersion_02];

scatter(f_all, v_all, 90, importance_vector, 'filled');
colormap(build_importance_colormap());
caxis([0 1]);
cb = colorbar;
cb.Ticks      = 0:0.1:1;
cb.TickLabels = arrayfun(@(x) sprintf('%.1f', x), 0:0.1:1, 'UniformOutput', false);
box on;
xlabel('Frequency [Hz]',      'FontSize', myFontSize);
ylabel('Phase velocity [m/s]','FontSize', myFontSize);
set(gca, 'FontName', 'Times New Roman', 'FontSize', myFontSize);
axis([0 100 170 510]);
set(gca, 'XTick', 0:20:100);
set(gca, 'YTick', 100:100:700);
fig.Position = [120 200 650 420];

%% training using top 20%,40%,60%,80% importance features
top_percentVector = [0.2 0.4 0.6 0.8]; % 20%,40%,60%,80%
inversionCell_save = cell(length(top_percentVector),7);
MAPE_importance_cell = cell(length(top_percentVector),1);

[~, idx] = sort(importance_vector, 'descend');

for mmm = 1:length(top_percentVector)
    
top_percent = top_percentVector(mmm);
top_num = ceil(length(v_all)*top_percent);
idx_temp = idx(1:top_num);
idx_2 = sort(idx_temp);

fprintf('Waiting about one minute for inversion of %d%% velocity points:\n', ...
    top_percent*100);

train_x_importance = train_x(:,idx_2);

% validation datasets
validation_x = dispersions_R_true;
validation_x = validation_x(idx_2);

validation_y = borehole;
% Normalize data (mean=0, std=1)
[mean_x,std_x,train_x_norm_importance] = normalized_fun(train_x_importance);
[mean_y,std_y,train_y_norm] = normalized_fun(train_y);
validation_x_norm = zeros(size(validation_x,1),size(validation_x,2));
for i = 1:1:size(validation_x,2)
    validation_x_norm(:,i) = (validation_x(:,i)-mean_x(i))/std_x(i);
end

% BLS regression for inversion - top percent velocity points
[Y_hat_importance,all_index_importance,NumFea_hat_temp,NumWin_hat_temp,NumEnhan_hat_temp] = bls_regression_sub_noTest_importance(...
    train_x_norm_importance,train_y_norm,Fea_vec,Win_vec,Enhan_vec,validation_x,Vp_true,den_true,f,modes_num_vec,index_vec,index_vec_all,mean_y,std_y,validation_x_norm,idx_2);
dispersions_R_inverted_importance = calSynDispersion(Y_hat_importance,Vp_true,den_true,f,modes_num_vec,index_vec_all);

fprintf('The inverted Vs profile for %d%% velocity points:\n', ...
    top_percent*100);
disp(Y_hat_importance);

h_hat_importance = Y_hat_importance(1:layers_num-1);
Vs_hat_importance = Y_hat_importance(layers_num:end);

borehole_Vs_hat_importance_temp = cal_boreholeVs(Y_hat_importance(1:layers_num-1),Y_hat_importance(layers_num:end),h_00,dh);%%

borehole_Vs_hat_importance_15 = cal_boreholeVs(h_hat_importance,Vs_hat_importance,h_00_15,dh);
MAPE_Y_hat_importance_15 = mean(abs(borehole_Vs_hat_importance_15 - ...
    borehole_Vs_true_15)./borehole_Vs_true_15);%%

fprintf('MAPE of inverted profile for %d%% velocity points: %f%%\n', ...
    top_percent*100, MAPE_Y_hat_importance_15*100);
disp('-------------------------------------------------------------------')

MAPE_importance_cell{mmm,1} = MAPE_Y_hat_importance_15;

% save variables
inversionCell_save{mmm,1} = idx_2;
inversionCell_save{mmm,2} = Y_hat_importance;
inversionCell_save{mmm,3} = all_index_importance;
inversionCell_save{mmm,4} = [NumFea_hat_temp NumWin_hat_temp NumEnhan_hat_temp];
inversionCell_save{mmm,5} = dispersions_R_inverted_importance;
inversionCell_save{mmm,6} = train_x_importance;
inversionCell_save{mmm,7} = MAPE_Y_hat_importance_15;%%

end

%% plot for inversion results: top 20%,40%,60%,80% importance features
for mmm =  1:length(top_percentVector)
    
    idx_2 = inversionCell_save{mmm,1};
    Y_hat_importance = inversionCell_save{mmm,2};
    all_index_importance = inversionCell_save{mmm,3};
    para_temp = inversionCell_save{mmm,4};
    NumFea_hat_temp = para_temp(1);
    NumWin_hat_temp = para_temp(2);
    NumEnhan_hat_temp = para_temp(3);
    dispersions_R_inverted_importance = inversionCell_save{mmm,5};
    train_x_importance = inversionCell_save{mmm,6};
% plot inverted dipsersion curves
top_importance = importance_vector(idx_2);
figure()
fig = gcf; % Get current figure
scatter(f_all(idx_2), v_all(idx_2), 90, top_importance, 'filled');
hold on

my_linewidth = 2.5;
h2 = [Y_hat_importance(1:3) 0];
Vs = Y_hat_importance(4:end);
out = gpdc(h2,Vp_true,Vs,den_true,'fV',f_00);
out2 = rdivide(1, out(:, 2:end));
plot(f_00,out2(:,1)','Color',[255 0 0]/255,'LineWidth',my_linewidth);
out = gpdc(h2,Vp_true,Vs,den_true,'fV',f_01);
out2 = rdivide(1, out(:, 2:end));
plot(f_01,out2(:,2)','Color',[255 0 0]/255,'LineWidth',my_linewidth);
out = gpdc(h2,Vp_true,Vs,den_true,'fV',f_02);
out2 = rdivide(1, out(:, 2:end));
plot(f_02,out2(:,3)','Color',[255 0 0]/255,'LineWidth',my_linewidth);

colormap(build_importance_colormap());
caxis([0 1]);
cb = colorbar;
cb.Ticks      = 0:0.1:1;
cb.TickLabels = arrayfun(@(x) sprintf('%.1f', x), 0:0.1:1, 'UniformOutput', false);
box on;
xlabel('Frequency [Hz]',      'FontSize', myFontSize);
ylabel('Phase velocity [m/s]','FontSize', myFontSize);
set(gca, 'FontName', 'Times New Roman', 'FontSize', myFontSize);
axis([0 100 170 510]);
set(gca, 'XTick', 0:20:100);
set(gca, 'YTick', 100:100:700);
fig.Position = [120 200 650 420];

% plot objective function curve
figure()
fig = gcf; % Get current figure
all_index_importance(:,1) = all_index_importance(:,1) - all_index_importance(1,1);
plot(all_index_importance(:,1),all_index_importance(:,2),'b','Linewidth',my_linewidth);
axis([0 40 0 15]);
xlabel('Time [s]','FontSize',myFontSize);
ylabel('Obj','FontSize',myFontSize);
set(gca,'FontName','Times New Roman','FontSize',myFontSize);

% plot inverted Vs profile
figure()
fig = gcf; % Get current figure
plot(borehole(:,2),borehole(:,1),':','Color',[150 150 150]/255,'Linewidth',my_linewidth);
hold on
temp = [h_true Vs_true];
drawMultiProfile_addSS(Y_hat_importance,temp(1:3),temp(4:end),Vs_profile_lower,Vs_profile_upper,myFontSize,my_linewidth)
fig.Position = [680,100,560,460];

end
