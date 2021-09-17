classdef Trial
    %% Summary of this class:
    % The class Trial takes in an excel trial file with the standard name
    % given for all test: [body]-[material]-[weight]-[targetside]-[date].
    
    % This class will identify all of these qualities and return them in
    % the given properties below as well as 4 labeled plots for that trial.
 
    properties
        
        body
        material
        weight
        side
        date
        goalper    % This is goal weight per 1-by-2m^2.
        table      % Table with all lanes and their collection values.
        prediction %(1)s table (perfect trial with F1 score of 1).
        selection  % Targeted lanes.
        borders    % 1m lane(s) next to target lane.
        gutters    % Lanes 0,13, and non-target lanes +1m away.
        f1
        plots
        expected_collection  % Using passing values/weight from goalper.
        actual_collection    % Sum of entire collection.
        percent_collected_of_nominal % actual/expected
        accuracy  % AKA recall
        precision
        
        
    end
    
    methods (Static)
        
        function thisTrial = Trial(filename)
            
            %% Creating our constructor
            
            %% Identifying trial name 
            % Each trial is formatted:
            % [body]-[material]-[weight]-[targetside]-[date].xlsm
            
            % splitting text by hyphen
            temp = strsplit(filename, "-");
            
            % assigning each of the properties
            thisTrial.body = temp(1);
            thisTrial.material = temp(2);
            thisTrial.weight = str2num(temp(3));
            thisTrial.side = temp(4);
            
            % removing the .xlsm
            temp2 = strsplit(temp(5), '.');
            thisTrial.date = str2num(temp2(1));
            
            %% Goalper
            % goalper: 12.98 lb/lnmi = gm/m2 (from excel)
            thisTrial.goalper = (thisTrial.weight / 12.98)*2;
            
            %% Complete Table
            % getting the actual data
            thisTrial.table = Trial.importfile(filename, "PLOTS");
            
            %% Selections
            % making the selection according to side
            [thisTrial.selection, thisTrial.gutters, thisTrial.prediction,...
                thisTrial.borders] = Trial.sideselection(thisTrial.table,...
                thisTrial.side);
            
            %% F1
            % f1scoring
            [thisTrial.f1, thisTrial.percent_collected_of_nominal,...
                thisTrial.expected_collection, thisTrial.actual_collection,...
                thisTrial.accuracy, thisTrial.precision] = Trial.f1score(thisTrial.selection,...
                thisTrial.gutters, thisTrial.goalper, thisTrial.borders);
            
            %% Plots
            % initializing plots
            thisTrial.plots = Trial.plotting(thisTrial.table, thisTrial.body,...
                thisTrial.material, thisTrial.weight, thisTrial.side, thisTrial.date);
        end
        
        
        function [f1, percent, tot_expected, tot_collected,...
                recall, precision] = f1score(selection, gutters, goal, borders)
 
            %% finding accuracy in the model
            
            % range of accepted values
            good = goal * 0.75;
            accepted_border = goal * 0.50;
            accepted_gutter = goal * 0.25;
            
            % table to matrix for ease of handling by element
            % accounting for the all test, when there is no borders
            newselection = selection{:,:};
            newgutters = gutters{:,:};
            if isempty(borders) == 1
                newborders = [];
            else
                newborders = borders{:,:};
            end
            
            % expected collection using above 'good' and 'accepted_gutter'
            expected_selection= numel(newselection) * good;
            expected_gutter  = numel(newgutters) * accepted_gutter;
            expected_borders = numel(newborders) * accepted_border;
            tot_expected = expected_selection + expected_gutter + expected_borders;
            % actual collected
            tot_collected = sum(newselection, 'all') + sum(newgutters, 'all') + ...
                sum(newborders, 'all');
            
            % percent collected from 'nominal'
            percent = (tot_collected / tot_expected) * 100;
            
            % actual binary matrix true/false
            actual_target = newselection >= good;
            actual_gutter = newgutters <= accepted_gutter;
            actual_border = newborders <= accepted_border;
            
            % True positives: values in target that reached goal
            % True negatives: values in target that failed to reach goal
            % False positives: values in gutter/border higher than 25/50% nominal
            % False negatives: values in gutter/border lower than 25/50% nominal
            TP = sum(actual_target, 'all');
            TN = numel(actual_target) - TP;
            FN = sum(actual_gutter, 'all') + sum(actual_border, 'all');
            FP = numel((actual_gutter)) + numel((actual_border)) - FN;
            total = TP + TN + FN + FP;
            accuracy = (TP + TN) / total;
            
            % Precision effectively describes the purity of our 
            % positive detections relative to the ground truth.
            precision = TP / (TP + FP);
   
            % Recall effectively describes the completeness of our 
            % positive predictions relative to the ground truth
            % A low recall indicates many False Negatives.
            recall = TP / (TP + FN);
            
            % F1 score conveys the balance between precision and recall.
            % Higher score = better. Range 0-1.
            
            f1 = 2*((precision*recall)/(precision+recall));
            
            % NAN
            if TP == 0 
                f1 = "NaN";
            end
            if isnan(recall)
                recall = "NaN";
            end
            if isnan(precision)
                precision = "NaN";
            end
            
            
        end
        
        function ans = plotting(table, body, material, weight, side, date)
        
            %% creating a visual plotting tool
            
            % table to matrix
            newtable = table{:,:};
            
            ans = tiledlayout(2,2);
            
            % Tile 1 (Surface Plot)
            nexttile
            surf(newtable);
            xlabel('Lanes');
            title('Surface Plot:');
            
            % Tile 2 (Countour Plot)
            nexttile
            contour(newtable);
            xlabel('Lanes');
            title('Countour Plot');
            
            % Tile 3 (Scaled Color)
            nexttile
            imagesc(newtable);
            xlabel('Lanes');
            title('Scaled Color Plot');
            
            % Tile 4 (Heatmap)
            nexttile
            heatmap(newtable);
            xlabel('Lanes');
            title('Heatmap Plot');
            
            % shared titles
            sgtitle([body + ' ' + material + ' ' + weight + ' ' + side + ' ' + date]);
            
            
        end
        
        function [selection, gutter, predicted, borders] = sideselection(table, side)
            
            %% delegating test lanes
            if side == 'R'
                gutter = [table(:,1:4), table(:,14)];
                selection = table(:,6:13);
                borders = table(:,5);
                predicted = ones(10,14);
            elseif side == 'L'
                gutter = [table(:,1), table(:,11:14)];
                selection = table(:,2:9);
                borders = table(:,10);
                predicted = ones(10,14);
            elseif side == 'C'
                gutter = [table(:,1:4), table(:,11:14)];
                selection = table(:,6:9);
                borders = [table(:,5), table(:,10)];
                predicted = ones(10,14);
            elseif side == 'A'
                gutter = [table(:,1), table(:,14)];
                selection = table(:,2:13);
                borders = {};
                predicted = ones(10,14);
            else
                disp("Spread does not have dessignated side")
            end
            
        end
        
        
        function ans = importfile(workbookFile, sheetName, dataLines)
            
            %% If no sheet is specified, read first sheet
            if nargin == 1 || isempty(sheetName)
                sheetName = 1;
            end
            
            % If row start and end points are not specified, define defaults
            if nargin <= 2
                dataLines = [22, 31];
            end
            
            % Setup the Import Options and import the data
            opts = spreadsheetImportOptions("NumVariables", 14);
            
            % Specify sheet and range
            opts.Sheet = sheetName;
            opts.DataRange = "D" + dataLines(1, 1) + ":Q" + dataLines(1, 2);
            
            % Specify column names and types
            opts.VariableNames = ["Lane0", "Lane1", "Lane2", "Lane3", "Lane4", "Lane5",...
                "Lane6", "Lane7", "Lane8", "Lane9", "Lane10", "Lane11", "Lane12", "Lane13"];
            opts.VariableTypes = ["double", "double", "double", "double", "double", "double",...
                "double", "double", "double", "double", "double", "double", "double", "double"];
            
            % Import the data
            ans = readtable(workbookFile, opts, "UseExcel", false);
            
            for idx = 2:size(dataLines, 1)
                opts.DataRange = "D" + dataLines(idx, 1) + ":Q" + dataLines(idx, 2);
                tb = readtable(workbookFile, opts, "UseExcel", false);
                ans = [ans; tb]; %#ok<AGROW>
            end
            
        end
    end
end

