classdef symbol_level
    properties
        frame_settings;
        available_modulation_level;

        effect_bit_number;
        data_freq_symbols;
        info_freq_symbols;
        data_time_symbols;
        info_time_symbols;

        frame;
    end

    methods
        function obj = symbol_level(...
            frame_settings, ...
            max_modulation_level ...
        )
            obj.frame_settings = frame_settings;
            obj.available_modulation_level = [1, 2, 4:2:max_modulation_level];
        end

        function obj = generate_data_symbol(obj, source_bit)
            obj.effect_bit_number = length(source_bit);
            tail_zero_length = (ceil(length(source_bit) / 6) * 6) - length(source_bit);
            source_bit = [source_bit; zeros(tail_zero_length, 1)];

            source_bit = double(reshape(source_bit, 6, []));
            source_p = zeros(1, size(source_bit, 2));
            for i = 1:6
                source_p = source_p + (source_bit(i, :) * (2 ^ (i - 1)));
            end

            qam_source_p = qammod(source_p, 64);
            tail_zero_length = (ceil(length(qam_source_p) / length(obj.frame_settings.asi)) * length(obj.frame_settings.asi)) - length(qam_source_p);
            qam_source_p = [qam_source_p.'; zeros(tail_zero_length, 1)];
            obj.data_freq_symbols = reshape(qam_source_p, length(obj.frame_settings.asi), []);

            ifft_data = zeros(obj.frame_settings.fft_size, size(obj.data_freq_symbols, 2));
            ifft_data(obj.frame_settings.asi, :) = obj.data_freq_symbols;
            obj.data_time_symbols = ifft(ifft_data);
            obj.data_time_symbols = [obj.data_time_symbols(end - obj.frame_settings.cp_size:end, :); obj.data_time_symbols];

            max_v = max(abs(obj.data_time_symbols));
            obj.data_time_symbols = obj.data_time_symbols ./ (max_v) * 0.7;
        end

        function obj = generate_info_symbol(obj, file_info)
            file_ext = sprintf("File name: %s. File bit numer: %s.End info.", file_info, num2str(obj.effect_bit_number));
            file_ext = uint8(abs(char(file_ext)));
            file_ext_bit = zeros(8, length(file_ext));
            for i = 1:8
                file_ext_bit(i, :) = bitget(file_ext, i);
            end
            file_ext_bit = reshape(file_ext_bit, [], 1);
            qam_file_ext = qammod(file_ext_bit, 2);
            tail_zero_length = (ceil(length(qam_file_ext) / length(obj.frame_settings.asi)) * length(obj.frame_settings.asi)) - length(qam_file_ext);
            qam_file_ext = [qam_file_ext; zeros(tail_zero_length, 1)];
            obj.info_freq_symbols = reshape(qam_file_ext, length(obj.frame_settings.asi), []);

            ifft_data = zeros(obj.frame_settings.fft_size, size(obj.info_freq_symbols, 2));
            ifft_data(obj.frame_settings.asi, :) = obj.info_freq_symbols;
            obj.info_time_symbols = ifft(ifft_data);
            obj.info_time_symbols = [obj.info_time_symbols(end - obj.frame_settings.cp_size:end, :); obj.info_time_symbols];

            max_v = max(abs(obj.info_time_symbols));
            obj.info_time_symbols = obj.info_time_symbols ./ (max_v) * 0.7;
        end

        function obj = generate_frame(obj)
            frame_not_end = true;
            obj.frame = [];
            counter = 0;

            while frame_not_end
                switch counter
                    case 0
                        obj.frame = [obj.frame, obj.frame_settings.sync];
                    case 1
                        obj.frame = [obj.frame, obj.info_time_symbols];
                    case 2
                        obj.frame = [obj.frame, obj.frame_settings.dmrs];
                    case 3
                        obj.frame = [obj.frame, obj.data_time_symbols];
                    otherwise
                        frame_not_end = false;
                end

                counter = counter + 1;
            end
        end

        function frame = get_result(obj)
            frame = reshape(obj.frame, [], 1);
        end
    end
end