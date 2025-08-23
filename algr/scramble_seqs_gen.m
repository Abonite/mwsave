function final_scramble_seq = scramble_seqs_gen(polys, init_seqs, target_length, col)
    final_scramble_seq = zeros(target_length, 1);

    parfor i = 1:length(polys)
        final_scramble_seq = xor(final_scramble_seq, scramble_seq_gen(polys{i, 1}, init_seqs(:, i), target_length));
    end

    final_scramble_seq = reshape(final_scramble_seq, col, []);
end