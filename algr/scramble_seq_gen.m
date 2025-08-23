function scramble_seq = scramble_seq_gen(poly, init_seq, target_length)
    scramble_seq = zeros(target_length, 1);

    lfsr = init_seq;

    for i = 2:target_length
        b = 0;
        for p = 1:length(poly)
            b = xor(b, lfsr(p, 1));
        end
        lfsr = [b; lfsr(1:end - 1, 1)];
        scramble_seq(i, 1) = b;
    end
end