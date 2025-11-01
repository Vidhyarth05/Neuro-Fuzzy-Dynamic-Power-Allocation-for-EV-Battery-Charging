%% Third.m: GUI and Robust Allocation Algorithm
% Author: Vidhyarth & Kiruthik Pranav
% Purpose: Load trained model and run the interactive multi-battery allocation GUI.
clear; clc; close all;
%% --- 1. Load the Trained Model ---
fprintf('=== SMART POWER ALLOCATION SYSTEM ===\n');
fprintf('Loading the trained ANFIS model...\n');
try
    % NOTE: Xmin, Xmax, and trained_fis must be loaded from this file.
    % Assuming they are defined in the 'Smart_Allocation_ANFIS_Complete.mat' file.
    load('Smart_Allocation_ANFIS_Complete.mat');
    fprintf('✓ Model loaded successfully!\n\n');
catch ME
    errordlg('Could not find "Smart_Allocation_ANFIS_Complete.mat". Please run the training script first.', 'Model Not Found');
    rethrow(ME);
end
%% --- 2. Ask for Number of Batteries ---
num_batteries_input = inputdlg({'Enter the number of batteries to charge (1-10):'}, ... % CHANGED TEXT
    'Battery Count', [1 50], {'3'});
if isempty(num_batteries_input)
    fprintf('Demo cancelled by user.\n');
    return;
end
num_batteries = str2double(num_batteries_input{1});
% Validate input
if isnan(num_batteries) || num_batteries < 1 || num_batteries > 10 % CHANGED 2 to 1
    errordlg('Please enter a valid number between 1 and 10.', 'Invalid Input'); % CHANGED TEXT
    return;
end
%% --- 3. Create Dynamic Input GUI (MODIFIED) ---
% Create figure for input
fig = uifigure('Name', 'Smart Power Allocation - Battery Input (Robust)', ...
    'Position', [100, 100, 1000, 600], 'Color', [0.95, 0.95, 0.97]); % Wider figure
% Title
uilabel(fig, 'Text', ' SMART POWER ALLOCATION SYSTEM (ROBUST) ', ...
    'Position', [20, 550, 960, 40], ...
    'FontSize', 24, 'FontWeight', 'bold', ...
    'HorizontalAlignment', 'center', ...
    'FontColor', [0.1, 0.3, 0.7]);
uilabel(fig, 'Text', 'Enter battery parameters and their individual power limits', ...
    'Position', [20, 520, 960, 25], ...
    'FontSize', 14, ...
    'HorizontalAlignment', 'center', ...
    'FontColor', [0.3, 0.3, 0.3]);
% Create scrollable panel for battery inputs
panel = uipanel(fig, 'Position', [20, 80, 960, 420], ... % Wider panel
    'BackgroundColor', [1, 1, 1], ...
    'BorderType', 'line');
% Create grid layout inside panel
grid = uigridlayout(panel, [num_batteries + 1, 6]); % CHANGED from 5 to 6
row_height = 50; 
grid.RowHeight = repmat({row_height}, 1, num_batteries + 1);
grid.ColumnWidth = {'1.2x', '1x', '1x', '1x', '1x', '1.2x'}; % ADDED column for Max Power
grid.Padding = [10, 10, 10, 10];
grid.RowSpacing = 5; 
grid.ColumnSpacing = 5; 
grid.Scrollable = 'on';

% Column headers
headers = {'Battery', 'SOH (%)', 'Charge Temp (°C)', 'Discharge Temp (°C)', 'IR Proxy (V/A)', 'Max Safe Power (kW)'}; % ADDED Max Safe Power
header_colors = [0.2, 0.4, 0.8];
for col = 1:6 % CHANGED from 5 to 6
    lbl = uilabel(grid, 'Text', headers{col}, ...
        'FontWeight', 'bold', 'FontSize', 12, ...
        'HorizontalAlignment', 'center', ...
        'BackgroundColor', header_colors, ...
        'FontColor', [1, 1, 1]);
    lbl.Layout.Row = 1;
    lbl.Layout.Column = col;
end
% Create input fields for each battery
edit_fields = cell(num_batteries, 5); % CHANGED from 4 to 5 (4 states + 1 max power)
default_values = {
    [98, 25, 28, 2.8, 70]; % ADDED 70 kW Max
    [85, 35, 36, 3.5, 60]; % ADDED 60 kW Max
    [90, 45, 42, 3.1, 55]; % ADDED 55 kW Max
    [92, 30, 32, 2.9, 75]; 
    [80, 40, 38, 3.6, 50]; 
    [95, 28, 30, 2.7, 70]; 
    [88, 38, 40, 3.2, 60]; 
    [93, 26, 29, 2.8, 75]; 
    [82, 42, 44, 3.7, 50]; 
    [96, 24, 27, 2.6, 70]
};
for i = 1:num_batteries
    % Battery label (Coloring remains the same)
    battery_colors = [
        0.2, 0.6, 0.9;  % Blue
        0.2, 0.8, 0.4;  % Green
        0.9, 0.5, 0.2;  % Orange
        0.7, 0.3, 0.8;  % Purple
        0.9, 0.3, 0.3;  % Red
        0.3, 0.7, 0.7;  % Teal
        0.8, 0.6, 0.2;  % Gold
        0.5, 0.5, 0.9;  % Light Blue
        0.9, 0.4, 0.6;  % Pink
        0.4, 0.8, 0.5   % Light Green
    ];
    
    color_idx = mod(i-1, 10) + 1;
    
    battery_panel = uipanel(grid, 'BackgroundColor', battery_colors(color_idx, :), ...
        'BorderType', 'none');
    battery_panel.Layout.Row = i + 1;
    battery_panel.Layout.Column = 1;
    
    uilabel(battery_panel, 'Text', sprintf(' Battery %d', i), ...
        'Position', [0, 5, 150, 40], ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'FontColor', [1, 1, 1], ...
        'HorizontalAlignment', 'center');
    
    % Input fields
    defaults = default_values{min(i, 10)};
    for j = 1:5 % CHANGED from 4 to 5
        edit_fields{i, j} = uieditfield(grid, 'numeric', ...
            'Value', defaults(j), ...
            'HorizontalAlignment', 'center', ...
            'FontSize', 14, ...
            'BackgroundColor', [1, 1, 1]);
        edit_fields{i, j}.Layout.Row = i + 1;
        edit_fields{i, j}.Layout.Column = j + 1;
    end
end
% Station power input at bottom
station_panel = uipanel(fig, 'Position', [20, 20, 960, 50], ... % Wider panel
    'BackgroundColor', [0.95, 0.85, 0.3], ...
    'BorderType', 'line');
uilabel(station_panel, 'Text', ' Total Station Power (kW):', ...
    'Position', [20, 10, 250, 30], ...
    'FontSize', 16, 'FontWeight', 'bold');
station_power_field = uieditfield(station_panel, 'numeric', ...
    'Value', 150, ...
    'Position', [280, 10, 150, 30], ...
    'FontSize', 16, ...
    'HorizontalAlignment', 'center', ...
    'BackgroundColor', [1, 1, 1]);
% Compute button
compute_btn = uibutton(station_panel, 'Text', ' Compute Allocation', ...
    'Position', [500, 10, 200, 30], ...
    'FontSize', 14, 'FontWeight', 'bold', ...
    'BackgroundColor', [0.2, 0.7, 0.3], ...
    'FontColor', [1, 1, 1]);
% Cancel button
cancel_btn = uibutton(station_panel, 'Text', '✖ Cancel', ...
    'Position', [720, 10, 120, 30], ...
    'FontSize', 14, ...
    'BackgroundColor', [0.8, 0.2, 0.2], ...
    'FontColor', [1, 1, 1]);
%% --- 4. Button Callbacks ---
cancel_btn.ButtonPushedFcn = @(btn,event) close(fig);
compute_btn.ButtonPushedFcn = @(btn,event) computeAllocation(fig, edit_fields, station_power_field, num_batteries, Xmin, Xmax, trained_fis);
%% --- 5. Nested Function: Compute Allocation (MODIFIED FOR ROBUSTNESS) ---
function computeAllocation(fig, edit_fields, station_power_field, num_batteries, Xmin, Xmax, trained_fis)
    % Collect battery states and max power
    battery_states = zeros(num_batteries, 4);
    max_safe_power = zeros(num_batteries, 1); % New array for max power limit
    
    for bat = 1:num_batteries
        % Battery state features (SOH, chT, disT, IR_proxy)
        for param = 1:4
            battery_states(bat, param) = edit_fields{bat, param}.Value;
        end
        % Max Safe Power (5th input)
        max_safe_power(bat) = edit_fields{bat, 5}.Value; 
    end
    
    total_power = station_power_field.Value;
    
    % Validate inputs
    if any(battery_states(:,1) < 0 | battery_states(:,1) > 100)
        uialert(fig, 'SOH must be between 0 and 100%', 'Invalid Input');
        return;
    end
    if any(max_safe_power < 0)
        uialert(fig, 'Max Safe Power must be non-negative.', 'Invalid Input');
        return;
    end
    
    % Compute priority scores using ANFIS
    priority_scores = zeros(num_batteries, 1);
    for bat = 1:num_batteries
        current_state = battery_states(bat, :);
        % Normalization
        normalized_input = (current_state - Xmin) ./ (Xmax - Xmin + eps);
        normalized_input = max(0, min(1, normalized_input)); 
        
        % ANFIS Prediction 
        raw_prediction = evalfis(trained_fis, normalized_input); 
        
        % Clamp to [0, 1]
        priority_scores(bat) = max(0, min(1, raw_prediction));
    end
    
    % --- TWO-STEP ALLOCATION LOGIC (Hierarchical Constrained Allocation) ---
    
    % Step 1: Calculate DESIRED Power based on individual Max Safe Rate
    % The ANFIS score (0 to 1) acts as a utilization factor on the Max Safe Power.
    desired_power = priority_scores .* max_safe_power;
    total_desired_power = sum(desired_power);
    
    % Step 2: Scale the DESIRED Power down if it exceeds the TOTAL STATION POWER
    if total_desired_power > total_power
        % STATION CONSTRAINT IS ACTIVE (Need to scale down)
        
        % Calculate scaling factor (must be < 1)
        scaling_factor = total_power / total_desired_power;
        
        % Apply scaling factor to proportionally reduce all desired powers
        allocated_power = desired_power * scaling_factor;
        
    else
        % BATTERY CONSTRAINTS ARE ACTIVE (No scaling needed, allocation is safe)
        allocated_power = desired_power;
        % Note: In this case, sum(allocated_power) < total_power, meaning the station is underutilized.
    end
    
    % Display results in new figure FIRST.
    % Also pass Max Safe Power for display/analysis
    displayResults(battery_states, priority_scores, allocated_power, total_power, max_safe_power, num_batteries);

    % Close input window LAST to avoid DestroyedObject error.
    close(fig); 
end
%% --- 6. Results Display Function (MODIFIED for new robust logic) ---
function displayResults(battery_states, priority_scores, allocated_power, total_power, max_safe_power, num_batteries)
        % Create results figure
        results_fig = uifigure('Name', 'Smart Power Allocation - Results (Robust)', ...
            'Position', [150, 150, 1100, 700], ... % Wider figure
            'Color', [0.95, 0.95, 0.97]);
        
        % Title
        uilabel(results_fig, 'Text', ' SMART ALLOCATION RESULTS (ROBUST METHOD)', ...
            'Position', [20, 650, 1060, 40], ...
            'FontSize', 24, 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center', ...
            'FontColor', [0.1, 0.3, 0.7]);
        
        % Summary panel
        summary_panel = uipanel(results_fig, 'Position', [20, 560, 1060, 80], ...
            'BackgroundColor', [0.9, 0.95, 1], ...
            'BorderType', 'line');
        
        total_allocated_sum = sum(allocated_power);
        
        uilabel(summary_panel, 'Text', sprintf('Total Station Capacity: %.1f kW', total_power), ...
            'Position', [20, 45, 300, 25], ...
            'FontSize', 16, 'FontWeight', 'bold');
        
        uilabel(summary_panel, 'Text', sprintf('Total Power Allocated: %.1f kW', total_allocated_sum), ...
            'Position', [20, 15, 300, 25], ...
            'FontSize', 16, 'FontWeight', 'bold', ...
            'FontColor', [0.2, 0.6, 0.2]);
        
        uilabel(summary_panel, 'Text', sprintf('Number of Batteries: %d', num_batteries), ...
            'Position', [350, 30, 250, 25], ...
            'FontSize', 16);
        
        utilization = (total_allocated_sum / total_power) * 100;
        uilabel(summary_panel, 'Text', sprintf('Station Utilization: %.1f%%', utilization), ...
            'Position', [650, 30, 250, 25], ...
            'FontSize', 16, 'FontWeight', 'bold');
        
        % Results panel to contain the data grid
        results_panel = uipanel(results_fig, 'Position', [20, 100, 1060, 450], ...
            'BackgroundColor', [1, 1, 1]);
        
        % Results grid layout: Now 8 columns
        results_grid = uigridlayout(results_panel, [num_batteries + 1, 8]); 
        
        results_grid.RowHeight = [40, repmat({'fit'}, 1, num_batteries)];
        results_grid.ColumnWidth = {'0.6x', '0.8x', '0.8x', '0.8x', '0.8x', '1x', '1x', '1.2x'};
        results_grid.Padding = [10, 10, 10, 10];
        results_grid.RowSpacing = 5;
        results_grid.ColumnSpacing = 5;
        results_grid.Scrollable = 'on';

        % Headers: Now 8 columns
        headers = {'Battery', 'SOH (%)', 'chT (°C)', 'disT (°C)', 'IR (V/A)', 'Max Safe (kW)', 'Priority Score', 'Allocated Power (kW)'};
        header_colors = [0.2, 0.4, 0.8];
        for col = 1:8 % CHANGED from 7 to 8
            lbl = uilabel(results_grid, ...
                'Text', headers{col}, ...
                'FontWeight', 'bold', 'FontSize', 11, ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', header_colors, ...
                'FontColor', [1, 1, 1]);
            lbl.Layout.Row = 1;
            lbl.Layout.Column = col;
        end
        
        % Battery colors (copied from input section)
        battery_colors = [
            0.2, 0.6, 0.9; 0.2, 0.8, 0.4; 0.9, 0.5, 0.2; 0.7, 0.3, 0.8;
            0.9, 0.3, 0.3; 0.3, 0.7, 0.7; 0.8, 0.6, 0.2; 0.5, 0.5, 0.9;
            0.9, 0.4, 0.6; 0.4, 0.8, 0.5
        ];

        % Battery results: Now 8 columns
        for i = 1:num_batteries
            
            % Battery number label (Column 1)
            color_idx = mod(i-1, 10) + 1;
            
            bat_lbl = uilabel(results_grid, ...
                'Text', sprintf(' #%d', i), ...
                'FontSize', 14, 'FontWeight', 'bold', ...
                'FontColor', [1, 1, 1], ...
                'HorizontalAlignment', 'center', ...
                'BackgroundColor', battery_colors(color_idx, :));
            
            bat_lbl.Layout.Row = i + 1;
            bat_lbl.Layout.Column = 1;

            % Data fields (Columns 2-8)
            % Combine state, max_safe, priority, allocated_power
            data = [battery_states(i, :), max_safe_power(i), priority_scores(i), allocated_power(i)];
            
            for col = 2:8 % Iterate through 7 data points
                bg_color = [1, 1, 1];
                data_val = data(col-1);
                
                if col == 7  % Priority score column
                    if data_val > 0.7
                        bg_color = [0.8, 1, 0.8];
                    elseif data_val < 0.4
                        bg_color = [1, 0.9, 0.9];
                    else
                        bg_color = [1, 1, 0.9];
                    end
                end
                
                txt = sprintf('%.2f', data_val);
                if col == 6 || col == 8 % Max Safe Power or Allocated Power
                    txt = sprintf('%.1f kW', data_val);
                end
                if col == 2 % SOH
                    txt = sprintf('%.1f%%', data_val);
                end
                
                lbl_data = uilabel(results_grid, 'Text', txt, ...
                    'FontSize', 12, ...
                    'HorizontalAlignment', 'center', ...
                    'BackgroundColor', bg_color);
                
                lbl_data.Layout.Row = i + 1;
                lbl_data.Layout.Column = col;
            end
        end
        
        % Action buttons
        uibutton(results_fig, 'Text', ' Export Results', ...
            'Position', [350, 30, 150, 40], ...
            'FontSize', 14, ...
            'BackgroundColor', [0.3, 0.6, 0.9], ...
            'FontColor', [1, 1, 1], ...
            'ButtonPushedFcn', @(btn,event) exportResults());
        
        uibutton(results_fig, 'Text', '✓ Close', ...
            'Position', [520, 30, 150, 40], ...
            'FontSize', 14, ...
            'BackgroundColor', [0.2, 0.7, 0.3], ...
            'FontColor', [1, 1, 1], ...
            'ButtonPushedFcn', @(btn,event) close(results_fig));
        
        function exportResults()
            % Create results table
            Battery = (1:num_batteries)';
            SOH = battery_states(:, 1);
            ChargingTemp = battery_states(:, 2);
            DischargeTemp = battery_states(:, 3);
            IR_Proxy = battery_states(:, 4);
            MaxSafePower = max_safe_power; % NEW FIELD
            PriorityScore = priority_scores;
            AllocatedPower = allocated_power;
            
            results_table = table(Battery, SOH, ChargingTemp, DischargeTemp, ...
                IR_Proxy, MaxSafePower, PriorityScore, AllocatedPower); % NEW TABLE STRUCTURE
            
            % Save to file
            [file, path] = uiputfile('Allocation_Results_Robust.csv', 'Save Results');
            if file ~= 0
                writetable(results_table, fullfile(path, file));
                uialert(results_fig, 'Results exported successfully!', 'Success');
            end
        end
        
        % Print to console
        fprintf('\n========================================\n');
        fprintf('SMART POWER ALLOCATION RESULTS (ROBUST)\n');
        fprintf('========================================\n');
        fprintf('Total Station Capacity: %.1f kW\n', total_power);
        fprintf('Total Power Allocated: %.1f kW (%.1f%% of capacity)\n\n', total_allocated_sum, utilization);
        
        for i = 1:num_batteries
            fprintf('Battery %d:\n', i);
            fprintf('  State: SOH=%.1f%%, chT=%.1f°C, disT=%.1f°C, IR=%.2f V/A\n', battery_states(i,:));
            fprintf('  Max Safe Power: %.1f kW\n', max_safe_power(i));
            fprintf('  Priority Score: %.3f\n', priority_scores(i));
            fprintf('  Allocated Power: %.2f kW (%.1f%% of station capacity)\n\n', allocated_power(i), (allocated_power(i)/total_power)*100);
        end
        fprintf('========================================\n');
end
