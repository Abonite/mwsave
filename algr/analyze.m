clear;

Audio_sympling_frequence = 44100;
FFT_point = 32;
Cp_length = 4;
Audio_band_width = 20000;
Max_per_group_data_symbol_number = 32;
Dmrs_in_per_symbol = 3;
Dmrs_in_per_group = 10;

Modulate_mode = "Manual"; %%or Auto
Modulate_type = "High Order Modulation Priority"; %%or High Bitrate Priority; only effect in auto mode
Modulate_level = 1;
LDPC_bitrate = 5/6;

Simulation_bit_number = 10000;

%% Caculate the system parameters
sub_carrier_interval = Audio_sympling_frequence / FFT_point;
sub_carrier_number = floor(Audio_band_width / sub_carrier_interval);

dmrs_interval_in_frequency = floor(32 / dmrs_in_per_symbol);
dmrs_interval_in_time = floor(32 / dmrs_in_per_group);
total_dmrs_symbol_per_group = Dmrs_in_per_group * Dmrs_in_per_symbol;
total_data_symbol_per_group = (Max_per_group_data_symbol_number * sub_carrier_number) - total_dmrs_symbol_per_group;
%% Generate source bits
source_bits = randi([0, 1], [Simulation_bit_number, 1]);
%% Determine parameters
switch Modulate_mode
    case "Manual"
        prb_num = ceil(Simulation_bit_number / Modulate_level);
        group_num = prb_num / total_data_symbol_per_group; %The decimal part indicates an incomplete group

        
    case "Auto"
    otherwise
        err_id = "mwsave_analyze:SimulationParameterError";
        err_msg = sprintf("Unknown Modulate_mode: %s", Modulate_mode);
        UnknowSPException = MException(err_id, err_msg);
        throw(UnknowSPException);
end