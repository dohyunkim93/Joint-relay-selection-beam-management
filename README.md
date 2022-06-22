# Joint-relay-selection-beam-management

Source code for the joint relay and mode selection problem. We describe the usage of the code in three steps.

#######DISTRIBUTION REQUIREMENTS########
Tested on Tensorflow 1.15.2, Python 3.6 and Matlab R2019a

Required packages (python)
- gym
- stable_baselines
Required packages (Matlab)
- Statistics and Machine Learning Toolbox
######################################

(i) Channel generation
run main file 'Channel_state_evolution_ULA.m'. Default realization = 2000, K = 100. (K is the length of decision iterations)
Returns channel matrix with size (N_r, N_t, realization, K)
Get H_Tx_to_Rx, H_Tx_to_relay, and H_relay_to_Rx. (Individual runs of 'Channel_state_evolution_ULA.m'). 
run 'blockage_process.m' to obtain the channel matrix with separate blockage process.
--related files: laprnd.m, array_response_ULA.m, blockage_process.m.

(ii) Threshold-based heuristic
run main file 'heuristic.m'. Requires channel files for Tx-Rx, Tx-relay, and relay-Rx and tau_mode, tau_relay.
Obtain tau_mode, tau_relay by running 'best_threshold_exhaustive_search.m'
--related files: SE_compute.m, beam_sweep.m, best_threshold_exhaustive_search.m

(ii) Learning-based relay and mode selection
copy the channel generated in step (i).
run 'conversion_MATLAB_channel_to_Python_p.py' to generate the .p files used in the python codes.
run 'get_policy_and_model.py' to use the customGym enviroment, representing the threshold learning DRL algorithm. 
