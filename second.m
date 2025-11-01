%% Opt_2.m: ANFIS Training, Evaluation, and Behavior PLOTS
% Author: Vidhyarth
% Purpose: Train the ANFIS, evaluate performance, and generate justification plots.

clear; clc; close all; rng(1);

%% STEP 1: Load and Prepare Dataset
fprintf('=== SMART POWER ALLOCATION SYSTEM ===\n');
try
    T = readtable('Smart_Allocation_Fuzzy_Labels.csv');
catch ME
    fprintf('ERROR: Could not read "Smart_Allocation_Fuzzy_Labels.csv".\n');
    fprintf('Please ensure you have run the fuzzy label generation script first.\n');
    rethrow(ME);
end
fprintf('Dataset loaded: %d samples\n', height(T));

% Define features and target
inputs = {'SOH', 'chT', 'disT', 'IR_proxy'};
target = 'PowerAllocationFactor';
X = table2array(T(:, inputs));
Y = table2array(T(:, target));

%% STEP 2: Data Preprocessing and Splitting
Xmin = min(X); Xmax = max(X);
X_norm = (X - Xmin) ./ (Xmax - Xmin + eps);
Y_norm = Y; % Output is already [0, 1]

n_train = round(0.7 * size(X_norm, 1));
shuffle_idx = randperm(size(X_norm, 1));
X_train = X_norm(shuffle_idx(1:n_train), :);
y_train = Y_norm(shuffle_idx(1:n_train));
X_test = X_norm(shuffle_idx(n_train+1:end), :);
y_test = Y_norm(shuffle_idx(n_train+1:end));
training_data = [X_train, y_train];

%% STEP 3: Create and Train the Optimal ANFIS Model
fprintf('Creating and training the ANFIS model...\n');
% We use the [2 2 2 2] configuration which we found to be the most robust
numMFs = [2 2 2 2];
mfType = 'gbellmf';
genfis_opt = genfisOptions('GridPartition', 'NumMembershipFunctions', numMFs);
initial_fis = genfis(training_data(:,1:end-1), training_data(:,end), genfis_opt);
fprintf('ANFIS created: %d rules\n', length(initial_fis.Rules));

% Train the model
options = anfisOptions('InitialFIS', initial_fis, 'EpochNumber', 150, 'ValidationData', [X_test, y_test], 'DisplayANFISInformation', 0);
[trained_fis, training_error, ~, ~, checking_error] = anfis(training_data, options);

%% STEP 4: Evaluate the Final Model
y_pred = evalfis(X_test, trained_fis);
r2 = corr(y_test, y_pred)^2;
rmse_orig = sqrt(mean((y_test * 100 - y_pred * 100).^2));
fprintf('Final Model Performance -> R² Score: %.4f | RMSE: %.2f points\n', r2, rmse_orig);

%% STEP 5: Professional Visualization (Just like your friend's!)
figure('Position', [50, 50, 1400, 1000]);

% Plot 1: Training & Validation Convergence
subplot(2, 3, 1);
plot(training_error, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Training Error');
hold on;
plot(checking_error, 'g-', 'LineWidth', 2.5, 'DisplayName', 'Validation Error');
title('ANFIS Learning Convergence', 'FontWeight', 'bold');
xlabel('Training Epochs'); ylabel('RMSE'); grid on; legend;

% Plot 2: Actual vs Predicted
subplot(2, 3, 2);
plot(1:length(y_test), y_test*100, 'r-', 'LineWidth', 1.5, 'DisplayName', 'Actual Allocation');
hold on;
plot(1:length(y_pred), y_pred*100, 'b-', 'LineWidth', 1.5, 'DisplayName', 'ANFIS Predicted Allocation');
xlabel('Test Sample Index'); ylabel('Power Allocation (%)');
title('ANFIS Smart Power Allocation Prediction', 'FontWeight', 'bold');
legend('Location', 'northeast'); grid on; ylim([0, 110]);

% Plot 3: Performance Scatter
subplot(2, 3, 3);
scatter(y_test*100, y_pred*100, 60, 'b', 'filled', 'MarkerFaceAlpha', 0.7);
hold on; plot([0,100], [0,100], 'r--', 'LineWidth', 2);
title(sprintf('Model Accuracy (R² = %.3f)', r2), 'FontWeight', 'bold');
xlabel('Actual Allocation (%)'); ylabel('Predicted Allocation (%)');
axis equal; xlim([0,100]); ylim([0,100]); grid on;

% Plot 4: Residual Analysis
subplot(2, 3, 4);
residuals = (y_test - y_pred) * 100;
scatter(y_pred*100, residuals, 50, 'b', 'filled', 'MarkerFaceAlpha', 0.6);
title('Residual Analysis', 'FontWeight', 'bold');
xlabel('Predicted Values (%)'); ylabel('Residuals (%)');
yline(0, 'r--', 'LineWidth', 2); grid on;

% Plot 5: Error Distribution
subplot(2, 3, 5);
histogram(residuals, 20, 'FaceColor', 'b', 'FaceAlpha', 0.7, 'EdgeColor', 'black');
title(sprintf('Error Distribution (RMSE=%.1f)', rmse_orig), 'FontWeight', 'bold');
xlabel('Prediction Error (%)'); ylabel('Frequency'); grid on;

% Plot 6: Feature Importance (Simple Method)
subplot(2, 3, 6);
% This simple method uses standard deviation as a proxy for importance
importance = std(X_norm);
bar(importance, 'FaceColor', 'b', 'FaceAlpha', 0.8);
set(gca, 'XTickLabel', inputs, 'TickLabelInterpreter', 'none'); xtickangle(45);
title('Feature Importance Analysis', 'FontWeight', 'bold');
ylabel('Importance Score (Std. Dev.)'); grid on;

sgtitle('Smart Power Allocation: ANFIS Control System Analysis', ...
        'FontSize', 16, 'FontWeight', 'bold');

%% STEP 6: ANFIS Rule Surfaces (like anfisedit!)
figure('Position', [100, 100, 1200, 800]);
mean_X_norm = mean(X_norm); % Get average normalized values for unused inputs

% Surface Plot 1: SOH vs Charging Temperature (The most important relationship)
subplot(2, 2, 1);
[X1, X2] = meshgrid(linspace(0, 1, 50)); % SOH and chT normalized range
X_surf = [X1(:), X2(:), repmat(mean_X_norm(3:4), length(X1(:)), 1)];
Y_surf = evalfis(X_surf, trained_fis);
Y_surf = reshape(Y_surf, size(X1));
surf(X1*100, X2*(Xmax(2)-Xmin(2))+Xmin(2), Y_surf*100); % De-normalize for plotting
title('ANFIS Rule Surface: SOH vs Charging Temp');
xlabel('State of Health (SOH %)'); ylabel('Charging Temp (°C)'); zlabel('Power Allocation (%)');
colorbar; shading interp;

% Surface Plot 2: SOH vs Internal Resistance
subplot(2, 2, 2);
[X1, X4] = meshgrid(linspace(0, 1, 50)); % SOH and IR_proxy normalized range
X_surf2 = [X1(:), repmat(mean_X_norm(2:3), length(X1(:)), 1), X4(:)];
Y_surf2 = evalfis(X_surf2, trained_fis);
Y_surf2 = reshape(Y_surf2, size(X1));
surf(X1*100, X4*(Xmax(4)-Xmin(4))+Xmin(4), Y_surf2*100); % De-normalize for plotting
title('ANFIS Rule Surface: SOH vs IR Proxy');
xlabel('State of Health (SOH %)'); ylabel('IR Proxy (V/A)'); zlabel('Power Allocation (%)');
colorbar; shading interp;

% Contour plots for a 2D view
subplot(2, 2, 3);
contourf(X1*100, X2*(Xmax(2)-Xmin(2))+Xmin(2), Y_surf*100, 20);
title('Priority Contour: SOH vs Charging Temp');
xlabel('State of Health (SOH %)'); ylabel('Charging Temp (°C)'); colorbar;

subplot(2, 2, 4);
contourf(X1*100, X4*(Xmax(4)-Xmin(4))+Xmin(4), Y_surf2*100, 20);
title('Priority Contour: SOH vs IR Proxy');
xlabel('State of Health (SOH %)'); ylabel('IR Proxy (V/A)'); colorbar;

sgtitle('ANFIS Rule Surfaces: Smart Power Allocation System', 'FontSize', 14, 'FontWeight', 'bold');

%% STEP 7: Save and Summarize
save('Smart_Allocation_ANFIS_Complete.mat');
writeFIS(trained_fis, 'Smart_Allocation_Trained_ANFIS');

fprintf('\n=== PROJECT ANALYSIS COMPLETE AND READY FOR SUBMISSION ===\n');