function drawMultiProfile_addSS(Y_hat_all,h_true,Vs_true,Y_lower_boundry,Y_upper_boundry,myFontSize,my_linewidth)

Y_hat_interested = Y_hat_all(1,:);

Vs_real = Vs_true;
N_true = length(h_true);

lb_h_inverted = Y_lower_boundry(1:N_true);
lb_Vs_inverted = Y_lower_boundry(N_true+1:2*N_true+1);
up_h_inverted = Y_upper_boundry(1:N_true);
up_Vs_inverted = Y_upper_boundry(N_true+1:2*N_true+1);

lb_h_1 = [0 lb_h_inverted];
lb_h = zeros(1,length(lb_h_inverted));
for i = 1:1:length(lb_h_1)
    lb_h(i) = sum(lb_h_1(1:i));
end
lb_h = [lb_h 40.1]; % h_real
lb_Vs = lb_Vs_inverted; % Vs_real
up_h_1 = [0 up_h_inverted];
up_h = zeros(1,length(up_h_inverted));
for i = 1:1:length(up_h_1)
    up_h(i) = sum(up_h_1(1:i));
end
up_h = [up_h 40.1]; % h_inverted
up_Vs = up_Vs_inverted; % Vs_inverted
dh = 0.01;
dVs = 0.01;

temp1 = up_h;
temp2 = lb_h;

Vs_temp = Y_upper_boundry(5:end);
for i = 1:1:length(Vs_temp)-1
    if Vs_temp(i+1) < Vs_temp(i)
        temp1(i+1) = lb_h(i+1);
        temp2(i+1) = up_h(i+1);
    end
end
up_h = temp2;
lb_h = temp1;

x_lb = cell(1,length(Y_hat_interested)); % x_real
y_lb = cell(1,length(Y_hat_interested)); % y_real
x_up = cell(1,length(Y_hat_interested)); % x_inverted
y_up = cell(1,length(Y_hat_interested)); % y_inverted

for i = 1:1:length(Y_hat_interested)
    if mod(i,2) == 1
        y_lb{i} = [lb_h((i+1)/2) lb_h((i+1)/2+1)];
        x_lb{i} = ones(1,2)*lb_Vs((i+1)/2);

        y_up{i} = [up_h((i+1)/2) up_h((i+1)/2+1)];
        x_up{i} = ones(1,2)*up_Vs((i+1)/2);
    else
        if Vs_real(i/2) < Vs_real(i/2+1)
            x_lb{i} = [lb_Vs(i/2) lb_Vs(i/2+1)];
            x_up{i} = [up_Vs(i/2) up_Vs(i/2+1)];
        else
            x_lb{i} = [lb_Vs(i/2+1) lb_Vs(i/2)];
            x_up{i} = [up_Vs(i/2+1) up_Vs(i/2)];
        end
        y_lb{i} = ones(1,2)*lb_h(i/2+1);
        y_up{i} = ones(1,2)*up_h(i/2+1);
    end
    plot(x_lb{i},y_lb{i},'-.','Color',[150 150 150]/255,'Linewidth',my_linewidth);
    hold on
    plot(x_up{i},y_up{i},'-.','Color',[150 150 150]/255,'Linewidth',my_linewidth);
end

for iii = 1:1:size(Y_hat_all,1)

Y_hat_interested = Y_hat_all(iii,:);

h_real_1 = [0 h_true];
h_real = zeros(1,length(h_real_1));
for i = 1:1:length(h_real_1)
    h_real(i) = sum(h_real_1(1:i));
end
h_real = [h_real 25];
Vs_real = Vs_true;
dh = 0.01;
dVs = 0.01;

N_true = length(h_true);
h_inverted_1 = [0 Y_hat_interested(1:N_true)];
h_inverted = zeros(1,length(h_inverted_1));
for i = 1:1:length(h_real_1)
    h_inverted(i) = sum(h_inverted_1(1:i));
end
h_inverted = [h_inverted 25];
Vs_inverted = Y_hat_interested(N_true+1:end);
dh_2 = 0.01;
dVs_2 = 0.01;


x_real = cell(1,length(Y_hat_interested));
y_real = cell(1,length(Y_hat_interested));
x_inverted = cell(1,length(Y_hat_interested));
y_inverted = cell(1,length(Y_hat_interested));

for i = 1:1:length(Y_hat_interested)
    if mod(i,2) == 1       
        y_inverted{i} = [h_inverted((i+1)/2) h_inverted((i+1)/2+1)];
        x_inverted{i} = ones(1,2)*Vs_inverted((i+1)/2);
    else
        if Vs_inverted(i/2) < Vs_inverted(i/2+1)
            x_inverted{i} = [Vs_inverted(i/2) Vs_inverted(i/2+1)];
        else
            x_inverted{i} = [Vs_inverted(i/2+1) Vs_inverted(i/2)];
        end
        y_inverted{i} = ones(1,2)*h_inverted(i/2+1);
    end
    plot(x_inverted{i},y_inverted{i},'Color',[0 0 0] / 255,'Linewidth',my_linewidth);
    hold on
end


end


set(gca,'xaxislocation','top');
xlabel('Shear-wave velocity [m/s]','FontSize',myFontSize);
ylabel('Depth [m]','FontSize',myFontSize);
axis([0 800 0 15]);
box on
set(gca,'ydir','reverse')
set(gca,'FontName','Times New Roman','FontSize',myFontSize);
set(gca,'XTick',0:200:1000);
set(gca,'YTick',0:5:25);


end