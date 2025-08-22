FILE_PATH = "";
%% SETTINGS
% FRAME:
% SYNC | FRAME_INFO | DMRS | DATA | DATA | ... | DATA | DMRS | DATA | ... | SYNC | ......
SAMPLIE_RATE = 441000;  %Hz
FFT_SIZE = 512;
CP_SIZE = 4;
USE_DMRS = true;
DATA_SYMBOL_NUMBER_PER_GROUP = 9;
MAX_MODULATION_LEVEL = 8;
BIT_RATE = 1/3;

MAX_FREQ = 20000;       %Hz
MIN_FREQ = 20;          %Hz

SUBCARRIER_SPACING = SAMPLIE_RATE / FFT_SIZE;
AVAILABLE_SUBCARRIER_INDEX = (ceil(MIN_FREQ / SUBCARRIER_SPACING) + 1):((MAX_FREQ / SUBCARRIER_SPACING) - (ceil(MIN_FREQ / SUBCARRIER_SPACING)));

if mod(length(AVAILABLE_SUBCARRIER_INDEX), 2) == 0
    SYNC_ZC = zadoffChuSeq(13, length(AVAILABLE_SUBCARRIER_INDEX) + 1);
    SYNC_ZC = SYNC_ZC(1:end - 1, 1);

    DMRS_ZC = zadoffChuSeq(31, length(AVAILABLE_SUBCARRIER_INDEX) + 1);
    DMRS_ZC = DMRS_ZC(1:end - 1, 1);
else
    SYNC_ZC = zadoffChuSeq(13, length(AVAILABLE_SUBCARRIER_INDEX));
    DMRS_ZC = zadoffChuSeq(31, length(AVAILABLE_SUBCARRIER_INDEX));
end

FRAME_INFO = struct(...
    "sample_rate", SAMPLIE_RATE, ...
    "fft_size", FFT_SIZE, ...
    "cp_size", CP_SIZE, ...
    "dsnpg", DATA_SYMBOL_NUMBER_PER_GROUP, ...
    "asi", AVAILABLE_SUBCARRIER_INDEX, ...
    "use_dmrs", USE_DMRS, ...
    "sync", SYNC_ZC, ...
    "dmrs", DMRS_ZC ...
);
%%
bitlevel = bit_level(0, FRAME_INFO, MAX_MODULATION_LEVEL, BIT_RATE);