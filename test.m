clc
clear

% trial1 = Trial("FSH-S-700-C-0818.xlsm")

[file,path] = uigetfile('*.xlsm');
file = convertCharsToStrings(file);
trial1 = Trial(file)

% specifying the range and row of printing in excel
row = 0;
range = 'B' + string(row) + ':L' + string(row);

% calling respective fields
array = [trial1.body, trial1.material, trial1.weight, trial1.side, ...
    trial1.date, trial1.expected_collection, trial1.actual_collection,...
    trial1.percent_collected_of_nominal, trial1.accuracy,...
    trial1.precision, trial1.f1];

% File to upload to namme and values to update
% xlswrite('results.xlsx', array, range) 

% trial1.table
% trial1.selection
% trial1.borders