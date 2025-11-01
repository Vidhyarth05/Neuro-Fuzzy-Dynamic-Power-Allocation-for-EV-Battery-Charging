%% 1.m: Data Preparation, Fuzzy Labeling, and Feature Analysis PLOTS
% Author: Kiruthik
% Purpose: Clean data, generate target labels, and generate Feature Analysis Plots.

clear; clc; close all; rng(1); 
DATA_FILE = 'Battery_dataset.csv'; 
OUTPUT_LABELS_FILE = 'Smart_Allocation_Fuzzy_Labels.csv';

fprintf('--- 1. Data Preprocessing and Feature Engineering ---\n');
try
    T = readtable(DATA_FILE);
catch ME
    rethrow(ME);
end

% Preprocessing
T = removevars(T, {'battery_id', 'cycle'}); 
T = rmmissing(T); 
T.SOH(T.SOH < 0 | T.SOH > 100) = NaN;
T.BCt(T.BCt <= 0) = NaN;
T.RUL(T.RUL < 0) = NaN;
T.chI(T.chI <= 0) = NaN; 
T.chT(T.chT < 10) = NaN; 
T.disT(T.disT < 10) = NaN;
T = rmmissing(T); 

% Feature Engineering: Create IR_proxy
IR_proxy = T.chV ./ (T.chI + 1e-6); 

% Prepare full input feature table for analysis
input_features = table(T.chI, T.chV, T.chT, T.disI, T.disV, T.disT, T.BCt, T.SOH, T.RUL, IR_proxy, ...
                       'VariableNames', {'chI', 'chV', 'chT', 'disI', 'disV', 'disT', 'BCt', 'SOH', 'RUL', 'IR_proxy'});


fprintf('--- 2. Fuzzy Logic Label Generation ---\n');
% Create Mamdani FIS (SOH and chT inputs)
fis = mamfis('Name', "ChargingLogicExpert");
fis = addInput(fis, [75 100], 'Name', "SOH"); fis = addMF(fis, "SOH", 'trapmf', [75 75 80 85], 'Name', "Poor"); fis = addMF(fis, "SOH", 'trimf',  [80 87.5 95], 'Name', "Medium"); fis = addMF(fis, "SOH", 'trapmf', [90 95 100 100], 'Name', "Good");
fis = addInput(fis, [20 50], 'Name', "chT"); fis = addMF(fis, "chT", 'trapmf', [20 20 25 32], 'Name', "Cool"); fis = addMF(fis, "chT", 'trimf',  [30 36 42], 'Name', "Warm"); fis = addMF(fis, "chT", 'trapmf', [40 45 50 50], 'Name', "Hot");
fis = addOutput(fis, [0 1], 'Name', "PowerAllocationFactor"); fis = addMF(fis, "PowerAllocationFactor", 'trimf', [0 0.15 0.3], 'Name', "Slow"); fis = addMF(fis, "PowerAllocationFactor", 'trimf', [0.3 0.5 0.7], 'Name', "Medium"); fis = addMF(fis, "PowerAllocationFactor", 'trimf', [0.7 0.85 1.0], 'Name', "Fast");
rules = ["IF SOH is Good AND chT is Cool THEN PowerAllocationFactor is Fast"; "IF SOH is Good AND chT is Warm THEN PowerAllocationFactor is Fast"; "IF SOH is Good AND chT is Hot THEN PowerAllocationFactor is Slow"; "IF SOH is Medium AND chT is Cool THEN PowerAllocationFactor is Medium"; "IF SOH is Medium AND chT is Warm THEN PowerAllocationFactor is Medium"; "IF SOH is Medium AND chT is Hot THEN PowerAllocationFactor is Slow"; "IF SOH is Poor AND chT is Cool THEN PowerAllocationFactor is Medium"; "IF SOH is Poor AND chT is Warm THEN PowerAllocationFactor is Slow"; "IF SOH is Poor AND chT is Hot THEN PowerAllocationFactor is Slow"];
fis = addRule(fis, rules);

% Generate the target labels
fis_inputs = [T.SOH, T.chT];
PowerAllocationFactor = evalfis(fis, fis_inputs);
final_dataset = [input_features, table(PowerAllocationFactor)];


fprintf('--- 3. Feature Selection & Plotting ---\n');
% Define ALL 10 features and the target
inputs_all = final_dataset.Properties.VariableNames(1:end-1); 
X_full = table2array(final_dataset(:, inputs_all));
Y_target = final_dataset.PowerAllocationFactor;

% --- START FIGURE 1: FEATURE SELECTION JUSTIFICATION ---
figure('Name', 'Feature Selection Justification (P1 & P2)', 'Position', [50, 50, 1400, 650]);

% P1: Correlation Bar Plot (Predictive Power)
subplot(1, 2, 1);
correlation = abs(corr(X_full, Y_target)); 
bar(correlation, 'FaceColor', [0.1, 0.5, 0.8], 'FaceAlpha', 0.8);
set(gca, 'XTickLabel', inputs_all, 'TickLabelInterpreter', 'none'); 
xtickangle(45);
title('P1: Feature Importance (Predictive Power)', 'FontWeight', 'bold');
ylabel('Absolute Correlation Coefficient'); 
grid on;

% P2: Collinearity Matrix (Redundancy Check)
subplot(1, 2, 2);
R_full = corr(X_full);
R_labels = inputs_all;
imagesc(R_full); colormap(jet); colorbar; caxis([-1 1]); 
xticks(1:length(R_labels)); yticks(1:length(R_labels));
xticklabels(R_labels); yticklabels(R_labels);
title('P2: Collinearity Matrix (Identify Redundancy)', 'FontWeight', 'bold');
for i = 1:length(R_labels)
    for j = 1:length(R_labels)
        text(j, i, sprintf('%.2f', R_full(i, j)), 'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', 8);
    end
end
xtickangle(45);
sgtitle('Feature Selection Justification: Predictive Power vs. Redundancy', 'FontSize', 16, 'FontWeight', 'bold');
fprintf('Feature Selection Justification figure generated (P1 & P2).\n');


% --- Final Feature Selection ---
selected_features = {'SOH', 'chT', 'disT', 'IR_proxy'}; 
final_inputs_idx = ismember(final_dataset.Properties.VariableNames, selected_features);
X = table2array(final_dataset(:, final_inputs_idx));

% Save normalization parameters and training data for second.m
Xmin = min(X); Xmax = max(X);
save('Trained_Data_Parameters.mat', 'X', 'Y_target', 'Xmin', 'Xmax', 'selected_features');

fprintf('Opt_1.m complete. Data, labels, and parameters saved.\n');