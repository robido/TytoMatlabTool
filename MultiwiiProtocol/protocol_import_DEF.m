function [definitions_val definitions_strings def_size] = protocol_import_DEF(refresh)

persistent PROTO_DEF_VALS PROTO_DEF_STRINGS DEF_SIZE_

if(nargin < 1)
    refresh = 0;
end

%Only import if not already
if(isempty(PROTO_DEF_VALS) || refresh)
    % Import the file
    [numbers, strings] = xlsread('PROTOCOL_DEF.xls', 'Sheet1');
    numbers(isnan(numbers)) = 0 ;
    strings(1,:)=[]; %Delete header row
    PROTO_DEF_VALS = numbers;
    PROTO_DEF_STRINGS = strings;
    DEF_SIZE_ = size(numbers,1);
    disp('Protocol Definitions Imported');
end
definitions_val = PROTO_DEF_VALS;
definitions_strings = PROTO_DEF_STRINGS;
def_size = DEF_SIZE_;


