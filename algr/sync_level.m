classdef sync_level
    properties
        frame_infos;

        sync_v;
    end

    methods
        function obj = sync_level(frame_infos)
            obj.frame_infos = frame_infos;
        end

        function obj = main_sync(obj, wav_data)
            sync_seq = conj(obj.frame_infos.sync_t_d);
            seq_length = length(sync_seq);
            data_length = length(wav_data);
            c_sync_v = zeros(data_length - seq_length, 1);

            fft_size = obj.frame_infos.fft_size;
            cp_size = obj.frame_infos.cp_size;
            svsc = obj.frame_infos.asi(1);
            evsc = obj.frame_infos.asi(end);

            parfor i = 1:data_length - (2 * (fft_size + cp_size))
                ap = wav_data(i:min(i + fft_size, data_length), 1);
                bp = wav_data((i + fft_size + cp_size):min(i + fft_size + fft_size + cp_size, data_length), 1);
                org_seq = [ap, bp];
                freq_domain_org_seq = fft(org_seq, fft_size);
                freq_domain_org_seq = reshape(freq_domain_org_seq(svsc:evsc, :), [], 1);
                c_sync_v(i, 1) = sum(freq_domain_org_seq .* sync_seq);
            end
            obj.sync_v = c_sync_v;
        end

        function [max_value, max_value_index, near_max_value] = get_max_sync_v(obj, near_v)
            abs_sync_v = abs(obj.sync_v);
            max_value = max(abs_sync_v);
            max_value_index = find(abs_sync_v == max_value);
            near_max_value = abs_sync_v(max(max_value_index - near_v, 1):max_value_index + near_v);
        end
    end
end