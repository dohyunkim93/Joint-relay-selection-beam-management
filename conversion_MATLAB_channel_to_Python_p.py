import os
from os.path import dirname, join as pjoin
import scipy.io as sio
import numpy as np
import pickle

current_path = os.getcwd()
mat_fname = pjoin(current_path, 'Tx_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat')
mat_contents = sio.loadmat(mat_fname)

the_channels = mat_contents['H']
one_channel = the_channels[:,:,0,0]
print(np.shape(one_channel))

pickle.dump(the_channels, open("16_16_Tx_to_Rx_channel_data.p","wb"))

mat_fname = pjoin(current_path, 'Tx_relay_channel_realization_Nt_16_Nr_16_Ns_1.mat')
mat_contents = sio.loadmat(mat_fname)

the_channels = mat_contents['H']
one_channel = the_channels[:,:,0,0]
print(np.shape(one_channel))

pickle.dump(the_channels, open("16_16_Tx_to_relay_channel_data.p","wb"))

mat_fname = pjoin(current_path, 'relay_Rx_channel_realization_Nt_16_Nr_16_Ns_1.mat')
mat_contents = sio.loadmat(mat_fname)

the_channels = mat_contents['H']
one_channel = the_channels[:,:,0,0]
print(np.shape(one_channel))

pickle.dump(the_channels, open("16_16_relay_to_Rx_channel_data.p","wb"))