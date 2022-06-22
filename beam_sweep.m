function [i_star, j_star] = beam_sweep(channel,transmit_beam_indices,receive_beam_indices,SNR)
%%%%Assuming transmit/receive codebook size is number of transmit/receive antennas and
%%%%equal beamwidth.
% %%%%%%%%%Assumptions%%%%%%%%%%%%%%
% N_S = 1; %Assuming single stream
% L_t = 1; L_r = 1; %Single RF chain
% [N_r, N_t] = size(channel);
% %%%%%%%%%Assumptions%%%%%%%%%%%%%%

i_star = 0;
j_star = 0;
max_beam_measurement = 0;

for i = 1:transmit_beam_indices
    for j = 1:receive_beam_indices
        beam_measurement  = SE_compute(i,j,channel,SNR);
        if beam_measurement > max_beam_measurement
            i_star = i;
            j_star = j;
            max_beam_measurement = beam_measurement;
        end
    end
end

assert((i_star~=0)&&(j_star~=0),'beam sweep error i_star or j_star is equal to null')
return 