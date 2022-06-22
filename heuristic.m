clear,clc

% K = 100; %Total simulation iterations
% realization = 2000; %Total channel realizations

%% Channel matrix load
load('Tx_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat') %% Loads H_Tx_to_Rx, 
H_Tx_to_Rx = H;
load('Tx_relay_channel_realization_Nt_16_Nr_16_Ns_1.mat') %H_Tx_to_relay,
H_Tx_to_relay = H;
load('relay_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat') %H_relay_to_Rx,
H_relay_to_Rx = H;

%% Optimal threshold load
load('tau_relay_tau_mode.mat') %tau_relay, and tau_mode
tau_relay = tau_relay_star;
tau_mode = tau_mode_star;

%% Iteration of heuristic

%Get parameters from loaded channel
[N_r, N_t,realization,K] = size(H_Tx_to_Rx(:,:,reali,k));

action = 'direct link channel estimation'; %Initial action
i_star_direct = 1; j_star_direct = 1; %% Beam index of Tx-Rx link
i_star_indirect = 1; j_star_indirect = 1; %% Beam index of Tx-relay link
i_star_indirect_hop = 1; j_star_indirect_hop = 1; %% Beam index of relay-Rx link

average_rate = zeros(realization,K);
SNR = 0; %dB

for reali = 1:realization
    sum_rate = 0;
    for k = 1:K
        %assert(!strcmp(action,'direct link channel estimation')||!stcmp(action,'direct link data transmission')||!strcmp(action,'indirect link channel estimation')||!strcmp(action,'indirect link data transmission'))
        
        %%%%%%%%%%%%%%%%COMPUTE SUM RATE PER ACTION%%%%%%%%%%%%%%%%%%%
        %Assuming channel estimation takes one iteration and does not terminate early
        
        if strcmp(action,'direct link channel estimation')
            [i_star_direct, j_star_direct] = beam_sweep(H_Tx_to_Rx(:,:,reali,k),N_t,N_r,SNR);
            sum_rate = sum_rate + 0; % zero rate achieved from pilot signals
        elseif strcmp(action,'direct link data transmission')
            sum_rate = sum_rate + SE_compute(i_star_direct,j_star_direct,H_Tx_to_Rx(:,:,reali,k),SNR);
        elseif strcmp(action,'indirect link channel estimation')
            [N_r, N_t,~,~] = size(H_Tx_to_Rx(:,:,reali,k));
            [i_star_indirect, j_star_indirect] = beam_sweep(H_Tx_to_relay(:,:,reali,k),N_t,N_r,SNR);
            sum_rate = sum_rate + 0; % zero rate achieved from pilot signals
        elseif strcmp(action,'indirect link data transmission')
            SE_1st_hop = SE_compute(i_star_indirect,j_star_indirect,H_Tx_to_relay(:,:,reali,k),SNR);
            SE_2nd_hop = SE_compute(i_star_indirect_hop,j_star_indirect_hop,H_relay_to_Rx(:,:,reali,k),SNR);
            sum_rate = sum_rate + (SE_1st_hop)*(SE_2nd_hop)/(SE_1st_hop+SE_2nd_hop);
        end
        
        average_rate(reali,k) = sum_rate/k;
        
        %%%%%%%%%%%%%%DETERMINE NEXT ACTION%%%%%%%%%%%%%%%%%%%%%%%
        
        if strcmp(action,'direct link channel estimation')
            action = 'direct link data transmission'; %Assuming channel estimation takes one iteration and does not terminate early
        elseif strcmp(action,'direct link data transmission')
            if SE_compute(i_star_direct,j_star_direct,H_Tx_to_Rx(:,:,reali,k),SNR) < tau_relay
                action = 'indirect link data transmission';
            elseif SE_compute(i_star_direct,j_star_direct,H_Tx_to_Rx(:,:,reali,k),SNR) < tau_mode
                action = 'direct link channel estimation';
            else
                action = 'direct link data transmission';
            end
        elseif strcmp(action,'indirect link channel estimation')
            action = 'indirect link data transmission'; %Assuming channel estimation takes one iteration and does not terminate early%Assuming channel estimation takes one iteration and does not terminate early
        elseif strcmp(action,'indirect link data transmission')
            if SE_compute(i_star_indirect,j_star_indirect,H_Tx_to_relay(:,:,reali,k),SNR) < tau_relay
                action = 'indirect link data transmission';
            elseif SE_compute(i_star_indirect,j_star_indirect,H_Tx_to_relay(:,:,reali,k),SNR) < tau_mode
                action = 'direct link channel estimation';
            else
                action = 'direct link data transmission';
            end
        end
    end
end
