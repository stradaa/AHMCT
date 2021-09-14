classdef Trial
    % Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        body
        material
        weight
        side
        date
        goalper
        table
        prediction
        selection
        gutters
        f1
        plots
        expected_collection
        actual_collection
        percent_collected_of_nominal
        accuracy
        precision
        
        
    end
    
    methods (Static)
        
        function thisTrial = Trial(filename)
            
            %% creating our constructor
          
            % splitting text by hyphen
            temp = strsplit(filename, "-");
            
            % assigning each of the properties
            thisTrial.body = temp(1);
            thisTrial.material = temp(2);
            thisTrial.weight = str2num(temp(3));
            
            % goalper: 12.98 lb/lnmi = gm/m2 (from excel)
            thisTrial.goalper = (thisTrial.weight / 12.98)*2;
            
            % side
            thisTrial.side = temp(4);
            
            % removing the .xlsm
            temp2 = strsplit(temp(5), '.');
            thisTrial.date = str2num(temp2(1));
            
            % getting the actual data
            thisTrial.table = Trial.importfile(filename, "PLOTS");
            
            % making the selection according to side
            [thisTrial.selection, thisTrial.gutters, thisTrial.prediction] = Trial.sideselection(thisTrial.table,...
                thisTrial.side);
            
            % f1scoring
            [thisTrial.f1, thisTrial.percent_collected_of_nominal,...
                thisTrial.expected_collection, thisTrial.actual_collection,...
                thisTrial.accuracy, thisTrial.precision] = Trial.f1score(thisTrial.selection, thisTrial.gutters, thisTrial.goalper);
            
            % initializing plots
            thisTrial.plots = Trial.plotting(thisTrial.table, thisTrial.body,...
                thisTrial.material, thisTrial.weight, thisTrial.side, thisTrial.date);
        end
        
        
        function [f1, percent, tot_expected, tot_collected,...
                recall, precision] = f1score(selection, gutters, goal)
 
            %% finding accuracy in the model
            
            % range of accepted values
            good = goal * 0.75;
            accepted_gutter = goal * 0.25;
            
            % table to matrix
            newselection = selection{:,:};
            newgutters = gutters{:,:};
            
            % expected collection using above 'good' and 'accepted_gutter'
            expected_selection= numel(newselection) * good;
            expected_gutter  = numel(newgutters) * accepted_gutter;
            tot_expected = expected_selection + expected_gutter;
            % actual collected
            tot_collected = sum(newselection, 'all') + sum(newgutters, 'all');
            % percent collected from 'nominal'
            percent = (tot_collected / tot_expected) * 100;
            
            % actual binary matrix true/false
            actual_target = newselection >= good
            actual_gutter = newgutters <= accepted_gutter
            
            % True positives: values in target that reached goal
            % True negatives: values in target that failed to reach goal
            % False positives: values in gutter higher than 25% nominal
            % False negatives: values in gutter lower than 25% nominal
            TP = sum(actual_target, 'all');
            TN = numel(actual_target) - TP;
            FN = sum(actual_gutter, 'all');
            FP = numel((actual_gutter)) - FN;
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
            ans = 0;
%             ans = tiledlayout(2,2);
%             
%             % Tile 1
%             nexttile
%             surf(newtable);
%             xlabel('Lanes');
%             title('Surface Plot:');
%             
%             % Tile 2
%             nexttile
%             contour(newtable);
%             xlabel('Lanes');
%             title('Countour Plot');
%             
%             % Tile 3
%             nexttile
%             imagesc(newtable);
%             xlabel('Lanes');
%             title('Scaled Color Plot');
%             
%             % Tile 4
%             nexttile
%             heatmap(newtable);
%             xlabel('Lanes');
%             title('Heatmap Plot');
%             
%             % shared titles
%             sgtitle([body + ' ' + material + ' ' + weight + ' ' + side + ' ' + date]);
%             
            
        end
        
        function [selection, gutter, predicted] = sideselection(table, side)
            
            %% delegating test lanes
            if side == 'R'
                gutter = [table(:,1:4), table(:,14)];
                selection = table(:,5:13);
                predicted = ones(10,14);
            elseif side == 'L'
                gutter = [table(:,1), table(:,11:14)];
                selection = table(:,2:10);
                predicted = ones(10,14);
            elseif side == 'C'
                gutter = [table(:,1:4), table(:,11:14)];
                selection = table(:,5:10);
                % predicted = [zeros(10,4), ones(10,6), zeros(10,4)]
                predicted = ones(10,14);
            elseif side == 'A'
                gutter = [table(:,1), table(:,14)];
                selection = table(:,2:13); 
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

