load('Tx_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat') %% Loads H_Tx_to_Rx, 
H_Tx_to_Rx = H;
load('Tx_relay_channel_realization_Nt_16_Nr_16_Ns_1.mat') %H_Tx_to_relay,
H_Tx_to_relay = H;
load('relay_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat') %H_relay_to_Rx,
H_relay_to_Rx = H;

blocked_Tx_to_Rx = zeros(size(H_Tx_to_Rx));
blocked_Tx_to_relay = zeros(size(H_Tx_to_relay));
blocked_relay_to_Rx = zeros(size(H_relay_to_Rx));
[N_r,N_t,realization,K] = size(H_Tx_to_Rx);

%%%2 STATE BLOCKAGE MARKOV CHAIN%%%
p_1 = 0.01; %Transition probability from not blocked to blocked
p_2 = 0.1; %Transition probability from blocked to blocked

blocked = 0; %Either 0 or 1
for reali = 1:realization
    for k = 2:K
        dummy_probability = rand();
        if dummy_probability<p_1 && blocked == 0
            blocked = 1;
            H_Tx_to_Rx(:,:,reali,k) = zeros(N_r,N_t);
        elseif dummy_probability>p_1 && blocked == 0
            blocked = 0;
        elseif dummy_probability<p_2 && blocked == 1
            blocked = 1;
            H_Tx_to_Rx(:,:,reali,k) = zeros(N_r,N_t);
        else
            blocked = 0;
        end
    end
end

blocked = 0; %Either 0 or 1
for reali = 1:realization
    for k = 2:K
        dummy_probability = rand();
        if dummy_probability<p_1 && blocked == 0
            blocked = 1;
            H_Tx_to_relay(:,:,reali,k) = zeros(N_r,N_t);
        elseif dummy_probability>p_1 && blocked == 0
            blocked = 0;
        elseif dummy_probability<p_2 && blocked == 1
            blocked = 1;
            H_Tx_to_relay(:,:,reali,k) = zeros(N_r,N_t);
        else
            blocked = 0;
        end
    end
end

blocked = 0; %Either 0 or 1
for reali = 1:realization
    for k = 2:K
        dummy_probability = rand();
        if dummy_probability<p_1 && blocked == 0
            blocked = 1;
            H_relay_to_Rx(:,:,reali,k) = zeros(N_r,N_t);
        elseif dummy_probability>p_1 && blocked == 0
            blocked = 0;
        elseif dummy_probability<p_2 && blocked == 1
            blocked = 1;
            H_relay_to_Rx(:,:,reali,k) = zeros(N_r,N_t);
        else
            blocked = 0;
        end
    end
end

% save('Tx_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat') %% H_Tx_to_Rx, 
% save('Tx_relay_channel_realization_Nt_16_Nr_16_Ns_1.mat') %H_Tx_to_relay,
% save('relay_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat') %H_relay_to_Rx,