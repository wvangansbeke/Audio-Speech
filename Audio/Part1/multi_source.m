for i = 1:num_mics
    mic(:,i) = fftfilt(RIR_sources(:,i), y);
end

