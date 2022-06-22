function [rate] = SE_compute(i_star,j_star,channel,SNR)
%%%%Assuming transmit/receive codebook size is number of transmit/receive antennas and
%%%%equal beamwidth.
%%%%%%%%%Assumptions%%%%%%%%%%%%%%
N_S = 1; %Assuming single stream
% L_t = 1; L_r = 1; %Single RF chain 
[N_r, N_t] = size(channel);
transmit_beam_indices = N_t;
receive_beam_indices = N_r;
SNR = 10^(SNR/10); %SNR input is in DB
%%%%%%%%%Assumptions%%%%%%%%%%%%%%

transmit_beam_angle = (i_star-1/2)*pi/transmit_beam_indices; %%equal beamwidth codebook.
receive_beam_angle = (j_star-1/2)*pi/receive_beam_indices; %%equal beamwidth codebook.
A_t = array_response_ULA(transmit_beam_angle,N_t); %ULA array response
A_r = array_response_ULA(receive_beam_angle,N_r);
rate = log2(det(eye(N_S) + SNR/N_S * pinv( A_r ) * channel * A_t * A_t' * channel' * A_r));
end