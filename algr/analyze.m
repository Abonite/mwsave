FILE_PATH = "H:\Code\rust\mwsave\LICENSE";
WAV_PATH = "H:\code\rust\mwsave\LICENSE_n.wav";
FILE_NAME = "LICENSE";

source_file = fopen(FILE_PATH, "r");
source_byte = uint8(fread(source_file));
source_bit = [];
for i = 1:length(source_byte)
    for j = 1:8
        s = int8(bitget(source_byte(i, 1), j));
        source_bit = [source_bit; s];
    end
end
%% SETTINGS
% FRAME:
% SYNC | FRAME_INFO | DMRS | DATA | DATA | ... | DATA | DMRS | DATA | ... | SYNC | ......
SAMPLIE_RATE = 192000;  %Hz
FFT_SIZE = 512;
CP_SIZE = 4;
USE_DMRS = true;
DATA_SYMBOL_NUMBER_PER_GROUP = 9;
MAX_MODULATION_LEVEL = 8;
BIT_RATE = 1/3;

MAX_FREQ = 20000;       %Hz
MIN_FREQ = 20;          %Hz

SUBCARRIER_SPACING = SAMPLIE_RATE / FFT_SIZE;
SUBCARRIERS = 0:SUBCARRIER_SPACING:MAX_FREQ;
AVAILABLE_SUBCARRIER_INDEX = (ceil(MIN_FREQ / SUBCARRIER_SPACING) + 1):((MAX_FREQ / SUBCARRIER_SPACING) - (ceil(MIN_FREQ / SUBCARRIER_SPACING)));

sync_zc = zadoffChuSeq(13, (length(AVAILABLE_SUBCARRIER_INDEX) * 2) + 1);
sync_zc = sync_zc(1:end - 1, 1);
ifft_data = zeros(FFT_SIZE, 2);
ifft_data(AVAILABLE_SUBCARRIER_INDEX, :) = reshape(sync_zc, length(AVAILABLE_SUBCARRIER_INDEX), []);
time_sync_zc = ifft(ifft_data);
SYNC_ZC = [time_sync_zc(end - CP_SIZE:end, :); time_sync_zc];
max_v = max(abs(SYNC_ZC));
SYNC_ZC = SYNC_ZC ./ (max_v) * 0.7;

if mod(length(AVAILABLE_SUBCARRIER_INDEX), 2) == 0
    dmrs_zc = zadoffChuSeq(31, length(AVAILABLE_SUBCARRIER_INDEX) + 1);
    dmrs_zc = dmrs_zc(1:end - 1, 1);
    ifft_data = zeros(FFT_SIZE, 1);
    ifft_data(AVAILABLE_SUBCARRIER_INDEX, :) = dmrs_zc;
    time_dmrs_zc = ifft(ifft_data);
    DMRS_ZC = [time_dmrs_zc(end - CP_SIZE:end, :); time_dmrs_zc];
    max_v = max(abs(DMRS_ZC));
    DMRS_ZC = DMRS_ZC ./ (max_v) * 0.7;
else
    dmrs_zc = zadoffChuSeq(31, length(AVAILABLE_SUBCARRIER_INDEX));
    ifft_data = zeros(FFT_SIZE, 1);
    ifft_data(AVAILABLE_SUBCARRIER_INDEX, :) = dmrs_zc;
    time_dmrs_zc = ifft(ifft_data);
    DMRS_ZC = [time_dmrs_zc(end - CP_SIZE:end, :); time_dmrs_zc];
    max_v = max(abs(DMRS_ZC));
    DMRS_ZC = DMRS_ZC ./ (max_v) * 0.7;
end

FRAME_INFO = struct(...
    "sample_rate", SAMPLIE_RATE, ...
    "fft_size", FFT_SIZE, ...
    "cp_size", CP_SIZE, ...
    "dsnpg", DATA_SYMBOL_NUMBER_PER_GROUP, ...
    "asi", AVAILABLE_SUBCARRIER_INDEX, ...
    "use_dmrs", USE_DMRS, ...
    "sync", SYNC_ZC, ...
    "dmrs", DMRS_ZC, ...
    "sync_t_d", real(sync_zc) + imag(sync_zc) ...
);

SCRAM_POLYS = struct(...
    "p1", [1, 5], ...
    "p2", [3, 7, 11, 23] ...
);
SCRAM_INIT = [...
    [1; 1; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0], ...
    [0; 0; 0; 0; 1; 0; 0; 1; 0; 0; 0; 1; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0; 0] ...
];

BIT_INFO = struct(...
    "crc_config", crcConfig(), ...
    "crc_length", 16, ...
    "scramble_polys", SCRAM_POLYS, ...
    "scramble_init", SCRAM_INIT ...
);
%%
bitlevel = bit_level(8448, FRAME_INFO, MAX_MODULATION_LEVEL, BIT_RATE, BIT_INFO);
bitlevel = bitlevel.encode(source_bit);
encoded_bits = bitlevel.get_result();
%%
symbollevel = symbol_level(FRAME_INFO, 8);
symbollevel = symbollevel.generate_data_symbol(encoded_bits);
symbollevel = symbollevel.generate_info_symbol(FILE_NAME);
symbollevel = symbollevel.generate_frame();
time_domain_data = symbollevel.get_result();
%%
sind = real(time_domain_data);
cosd = imag(time_domain_data);
wav_data = sind + cosd;
audiowrite(WAV_PATH, wav_data, SAMPLIE_RATE);
%%
test = wav_data(CP_SIZE:FFT_SIZE);
t = fft(test);
scatter(real(t), imag(t));
%%
% synclevel = sync_level(FRAME_INFO);
% synclevel = synclevel.main_sync(wav_data);
% [sync_v, sync_i, sync_n] = synclevel.get_max_sync_v(100);
% plot(1:length(sync_n), sync_n);