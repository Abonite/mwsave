classdef bit_level
    properties
        ldpc_set = [2, 3, 5, 7, 9, 11, 13, 15];
        ldpc_j = [7, 7, 6, 5, 5, 5, 4, 4];
        ldpc_t;

        block_length;
        bit_settings;
        frame_settings;
        available_modulation_level;
        bit_rate;
        target_block_length;

        encode_bit_length;
        code_blocks;
        added_crc_blocks;
        scramble_seqs;
        scrambled_blocks;
        ldpc_encoded_blocks;
        interleaved_bits;
    end

    methods
        function obj = bit_level(...
            block_length, ...
            frame_settings, ...
            max_modulation_level, ...
            bit_rate, ...
            bit_settings ...
        )
            obj.block_length = block_length;
            obj.frame_settings = frame_settings;
            obj.bit_settings = bit_settings;
            obj.available_modulation_level = [1, 2, 4:2:max_modulation_level];
            obj.bit_rate = bit_rate;

            obj.target_block_length = block_length / bit_rate;
            obj.ldpc_t = sum(obj.ldpc_set .* obj.ldpc_j);
        end

        function obj = encode(obj, file_bits)
            file_size = length(file_bits);
            if obj.block_length == 0
            else
                block_num = ceil(file_size / (obj.block_length - obj.bit_settings.crc_length));
                tail_zero_size = (block_num * (obj.block_length - obj.bit_settings.crc_length)) - file_size;
                file_bits = [file_bits; zeros(tail_zero_size, 1)];
                obj.encode_bit_length = block_num * obj.block_length;

                gss_o = parfeval(@generate_scramble_seq, 1, obj);
                obj.code_blocks = reshape(file_bits, [], block_num);
            end

            obj.added_crc_blocks = crcGenerate(obj.code_blocks, obj.bit_settings.crc_config);
            obj.scramble_seqs = fetchOutputs(gss_o);
            obj.scrambled_blocks = xor(obj.added_crc_blocks, obj.scramble_seqs);

            obj.ldpc_encoded_blocks = nrLDPCEncode(int8(obj.scrambled_blocks), 1);
            obj.ldpc_encoded_blocks = obj.ldpc_encoded_blocks(1:obj.target_block_length, :);
        end

        function scramble_seqs = generate_scramble_seq(obj)
            scramble_seqs = scramble_seqs_gen(...
                struct2cell(obj.bit_settings.scramble_polys), ...
                obj.bit_settings.scramble_init, ...
                obj.encode_bit_length, ...
                obj.block_length ...
            );
        end

        function encoded_bits = get_result(obj)
            encoded_bits = reshape(obj.ldpc_encoded_blocks, [], 1);
        end
    end
end