clc;
clear;
close all;

%% User Input Prompt
SaveY_N = questdlg('Would you like to use previous user input?', 'Previous Input?', 'Yes', 'No', 'No');
if strcmp(SaveY_N, 'Yes')
    PreviousInput = readcell('PreviousInput.txt');
    UserInput = cellstr(string(PreviousInput));
else
    prompt = {'Rated Power (VA):', 'Primary Voltage:', 'Secondary Voltage:', 'OC Voltage:', 'OC Current:', 'OC Power:', 'SC Voltage', 'SC Current:', 'SC Power:'};
    dlgtitle = 'Transformer Circuit Test';
    UserInput = inputdlg(prompt, dlgtitle);
end

%% Assigning UserInput as an array
inputs = cellfun(@str2double, UserInput);

S = inputs(1);
Vp = inputs(2);
Vs = inputs(3);
Voc = inputs(4);
Ioc = inputs(5);
Poc = inputs(6);
Vsc = inputs(7);
Isc = inputs(8);
Psc = inputs(9);

%% Transformer Function

%% if rated voltage matches any side, test was done 
%% Transformer Ratio
[num, den] = rat(Vp / Vs);
tolerance = 1e-2;
Np = num;
Ns = den;
a =  Vp/Vs;
Ip = (S/Vp);
Is = (S/Vs);

if Vp>Vs
    disp('Step Down: High voltage on primary side.')
    VH = Vp;
    VL = Vs;
    IH = Ip;
    IL = Is;
elseif Vp<Vs
    disp('Step Up: Low voltage on primary side.')
    VL = Vp;
    VH = Vs;
    IL = Ip;
    IH = Is;
end
if Voc == VL
    disp('Open circuit test was done on the low voltage side')
    RcL = Voc^2/Poc;
    RcL2 = RcL; % renaming purposes
    Soc = Voc*Ioc;
    Qoc = sqrt(Soc^2-Poc^2);
    XmL = Voc^2/Qoc;
    XmL2 = XmL; % Rename
    if Vp>Vs
        RcH = a^2*RcL; % --1
        RcH2 = RcH; % rename purposes
        XmH = a^2*XmL; % --
        XmH2 = XmH; % rename purposes
    elseif Vp<Vs
        RcH = RcL/a^2; % --1
        RcH2 = RcH; % rename purposes
        XmH = XmL/a^2; % --
        XmH2 = XmH; % rename purposes            
    end
    
    if abs(Isc - IH) < tolerance
        disp('Short circuit test was done on the high voltage side')
        ReH = Psc/Isc^2;
        ZeH = Vsc/Isc;
        XeH = sqrt(ZeH^2-ReH^2);
        if Vp>Vs
            ReL = (ReH)/a^2; % --
            XeL = XeH/a^2; % --
        elseif Vp<Vs
            ReL = (ReH)*a^2; % --
            XeL = XeH*a^2; % --               
        end
        RH = 0.5*ReH;
        XH = 0.5*XeH;
        RL = 0.5*ReL;
        XL = 0.5*XeL;
    elseif abs(Isc - IL) < tolerance
        disp('Short circuit test was done on the low voltage side')
        ReL = Psc/Isc^2;
        ZeL = Vsc/Isc;
        XeL = sqrt(ZeL^2-ReL^2);
        ReH = (ReL)*a^2;
        XeH = XeL*a^2;
        RL = 0.5*ReL;
        XL = 0.5*XeL;
        RH = 0.5*ReH;
        XH = 0.5*XeH;
    end
end

%% Renaming the Blocks
diagramNames = {'TransformerDiagramHigh', 'TransformerDiagramLow'};
blockTypes = {'R', 'l'};
suffixes = {': ', ': j'};
names = {RcH, XmH, ReH, XeH, Np, Ns};

for diagramIdx = 1:numel(diagramNames)
    diagramName = diagramNames{diagramIdx};
    
    % Opens the Corresponding Block Diagram
    uiopen([diagramName '.slx'], 1);
    
    % Lists the Blocks
    list_of_blocks = find_system(diagramName, 'type', 'block');
    
    % Renames the Blocks
    for blockIdx = 1:numel(list_of_blocks)
        block = list_of_blocks{blockIdx};
        parameter = get_param(block, 'DialogParameters');
        field = fieldnames(parameter);
        fieldType = field{1}(1);  % Extracts the first character
        
        % Finds which blocks are resistors or inductors
        if ismember(fieldType, blockTypes)
            blockValueString = get_param(block, fieldType);
            blockValue = eval(blockValueString);
            suffix = suffixes{strcmp(fieldType, blockTypes)};
            blockName = [blockValueString, suffix, num2str(blockValue)];
            set_param(block, 'Name', blockName);
        elseif fieldType == 'n'  % Finds the transformer block
            blockName = [num2str(Np), ' : ', num2str(Ns)];
            set_param(block, 'Name', blockName);
        end
    end
end

%% Save User Input
SaveY_N = questdlg('Would you like to save this user input?', 'Save User Input?', 'Yes', 'No', 'Yes');
if strcmp(SaveY_N, 'Yes')
    writecell(UserInput, 'PreviousInput.txt');
end
