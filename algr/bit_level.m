classdef bit_level
    properties
        ldpc_set = [2, 3, 5, 7, 9, 11, 13, 15];
        ldpc_j = [7, 7, 6, 5, 5, 5, 4, 4];
        ldpc_t = sum(ldpc_set .* ldpc_j);

        block_length;
        frame_settings;
        available_modulation_level;
        bit_rate;

        code_blocks;
        added_crc_blocks;
        scrambled_blocks;
        ldpc_encoded_blocks;
        interleaved_bits;
    end

    methods
        function obj = bit_level(...
            block_length, ...
            frame_settings, ...
            max_modulation_level, ...
            bit_rate ...
        )
            obj.block_length = block_length;
            obj.frame_settings = frame_settings;
            obj.available_modulation_level = [1, 2, 4:2:max_modulation_level];
            obj.bit_rate = bit_rate;
        end

        function encoded_bits = encode(obj, file_bits)
            file_size = length(file_bits);
            if obj.block_length == 0
                infos = [];
                for mod_level = obj.available_modulation_level
                    for l_info = [obj.ldpc_set; obj.ldpc_j]
                        l_set = l_info(1, 1);
                        l_j = l_info(2, 1);
                        for j = 0:l_j
                            for kb = [10, 22]
                                zc = l_set * (2 ^ l_j);
                                source_block_size = zc * kb;
                                r = file_size / source_block_size;
                                
                                infos = [infos, [mod_level, ]]
                            end
                        end
                    end
                end
            else
            end            
        end
    end
end