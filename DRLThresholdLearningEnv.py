import numpy as np
from typing import Optional

from gym import Env, Space
from gym.spaces import Discrete, MultiDiscrete, MultiBinary, Box
from numpy.linalg import pinv

def conjT(matrix):
    return np.transpose(np.conj(matrix))

class DRLThresholdLearningEnv(Env):
    def __init__(self, channel_contents,
                 N_t = 16, N_r = 16,
                 L_t = 1, L_r = 1,
                 N_S = 1, SNRdB=0,
                 ep_length: int = 100):
                 #Change ep_length to the total time since we only consider a single episode of learning in communications
        """
        Beamforming environment implementing DRL-based hybrid precoding
        :param channel_contents: channel state information, including channel matrix, assumed to be imported from .mat file as a dictionary type data
                                 python dictionary type data, with keywords 'H'. Size is (N_r,N_t,realization,K)
        :param N_t: the number of transmit antennas
        :param N_r: the number of receiver antennas
        :param L_t: the number of RF chains in transmitter side
        :param L_r: the number of RF chains in receiver side
        :param N_S: the number of streams
        :param SNRdB: the SNR in dB scale
        :param ep_length: the length of each episode in timesteps
        """

        assert N_S <= L_t, "number of transmitter RF chains less than the number of streams"
        assert N_S <= L_r, "number of receiver RF chains less than the number of streams"

        self.N_t = N_t
        self.N_r = N_r
        self.L_t = L_t
        self.L_r = L_r
        self.N_S = N_S
        self.SNRdB = SNRdB
        self.SNR = 10**(0.1*SNRdB)
        self.channel_Tx_Rx = channel_contents[0]
        self.channel_Tx_relay = channel_contents[1]
        self.channel_relay_Rx = channel_contents[2]
        channel_Tx_Rx = self.channel_Tx_Rx
        channel_Tx_relay = self.channel_Tx_relay
        channel_relay_Rx = self.channel_relay_Rx

        self.relay_index = 0 # 0 for direct link, 1 for indirect link
        self.transmission_mode = 0 # 0 for channel estimation, 1 for data transmission
        
        self.num_states = 3*3 
        '''
        3 is from the tuple (transmitter beam index, receiver beam index, beam measurement), 3 is from the two types (direct or indirect) of links
        where direct link has one hop of tuple to save, and indirect link has two hop of tuple to save
        '''
        self.num_actions = 2 # first action is tau_relay in dB, absolute value of second action is added to first action to get tau_mode in dB. 
        num_actions = self.num_actions

        self.reward = 0

        self.action_lower_bound = []
        for _ in range(num_actions):
            self.action_lower_bound.append(-100)
        self.action_lower_bound = np.array(self.action_lower_bound)
        self.action_upper_bound = []
        for _ in range(num_actions):
            self.action_upper_bound.append(100)
        self.action_upper_bound = np.array(self.action_upper_bound)
        self.state_lower_bound = []
        for _ in range(num_actions):
            self.state_lower_bound.append(-100)
        self.state_lower_bound = np.array(self.state_lower_bound)
        self.state_upper_bound = []
        for _ in range(num_actions):
            self.state_upper_bound.append(100)
        self.state_upper_bound = np.array(self.state_upper_bound)


        self.action_space = Box(self.action_lower_bound,self.action_upper_bound,dtype=np.float64) 
        self.observation_space = Box(self.state_lower_bound,self.state_upper_bound,dtype=np.float64)

        self.state = self.observation_space.sample()
        self.action = self.action_space.sample()

        self.ep_length = ep_length
        self.current_step = 0 # Tracks iteration number
        self.num_resets = -1  # Becomes 0 after __init__ exits.
        self.reset()

    def reset(self):
        self.current_step = 0
        self.num_resets += 1
        self._choose_next_state()
        return self.state

    def step(self, action):
        self.action = action #CRITICAL LINE: Do this to save action made to save action
        reward = self._get_reward(action)
        self._choose_next_state(self.state)
        self.current_step += 1
        done = self.current_step >= self.ep_length
        return self.state, reward, done, {}
    
    def _choose_next_state(self.state):        
        temp = self.state
        rate_of_current_link = 0
        if transmission_mode == 0: #When transmission mode is channel estimation
            transmission_mode = 1 #Assuming channel estimation takes one iteration and does not terminate early
            if relay_index == 0:
                i_star_Tx_Rx,j_star_Tx_Rx,beam_measurement_Tx_Rx = beam_sweeping(self.current_step,channel_Tx_Rx[:,:,0,current_step],N_t,N_r,SNR)
                temp[0] = i_star_Tx_Rx
                temp[1] = j_star_Tx_Rx
                temp[2] = beam_measurement_Tx_Rx
            elif relay_index == 1:
                i_star_Tx_relay,j_star_Tx_relay,beam_measurement_Tx_relay = beam_sweeping(self.current_step,channel_Tx_relay[:,:,0,current_step],N_t,N_r,SNR)
                i_star_relay_Rx,j_star_relay_Rx,beam_measurement_relay_Rx = beam_sweeping(self.current_step,channel_relay_Rx[:,:,0,current_step],N_t,N_r,SNR)    
                temp[3] = i_star_Tx_relay
                temp[4] = i_star_relay_Rx
                temp[5] = beam_measurement_Tx_relay
                temp[6] = i_star_relay_Rx
                temp[7] = j_star_relay_Rx
                temp[8] = beam_measurement_relay_Rx
            #Update state
            self.state = temp
        elif transmission_mode == 1:
            if relay_index == 0:
                rate_of_current_link = SE_computation(int(temp[0]),int(temp[1]),channel_Tx_Rx[:,:,0,current_step],SNR)
            elif relay_index == 1:
                R_1st_hop = SE_computation(int(temp[3]),int(temp[4]),channel_Tx_relay[:,:,0,current_step],SNR)
                R_2nd_hop = SE_computation(relay_codebook_index,Rx_codebook_index,channel_relay_Rx[:,:,0,current_step],SNR)
                rate_of_current_link = R_1st_hop*R_2nd_hop/(R_1st_hop+R_2nd_hop)
            if rate_of_current_link<log2(1+10**(0.1*action[0])) # rate is lower than tau_relay
                relay_index = 1-relay_index
            elif rate_of_current_link<log2(1+10**(0.1*action[1])) # rate is lower than tau_mode
                transmission_mode = 1-transmission_mode

    def _get_reward(self, action):
        SNR = self.SNR
        # Source-destination can be one of Tx-Rx, Tx-relay, and relay-Rx
        Tx_codebook_index = 0
        relay_codebook_index = 0 
        Rx_codebook_index = 0

        if relay_index == 0:
            R = SE_computation(Tx_codebook_index,Rx_codebook_index,channel_Tx_Rx[:,:,0,current_step],SNR)
        if relay_index == 1:
            R_1st_hop = SE_computation(Tx_codebook_index,relay_codebook_index,channel_Tx_relay[:,:,0,current_step],SNR)
            R_2nd_hop = SE_computation(relay_codebook_index,Rx_codebook_index,channel_relay_Rx[:,:,0,current_step],SNR)
            R = R_1st_hop*R_2nd_hop/(R_1st_hop+R_2nd_hop)

        self.reward = np.log2(2.718281)*R*self.transmission_mode
        return np.log2(2.718281)*R*self.transmission_mode #Convert from log10 to log2, if transmission mode is 0 (channel estimation) zero rate

    def array_response(angle, N):
        # Assuming N is a power of 2
        y = np.zeros(shape=(N,1),dtype=np.complex128)
        for m in range(N):
            y[m] = np.exp(1j* np.pi*(m*np.sin(angle)))
        y = y/np.sqrt(N)
        return y

    def SE_computation(i_index,j_index,channel,SNR):
        # Assuming transmit/receive codebook size is number of transmit/receive antennas and equal beamwidth
        transmit_beam_angle = (i_index-1/2)*np.pi/N_t
        receive_beam_angle = (j_index-1/2)*np.pi/N_r
        A_t = array_response(transmit_beam_angle,N_t)
        A_r = array_response(receive_beam_angle,N_r)
        R_n = np.linalg.multi_dot([conjT(A_r),A_r])
        _, R = np.linalg.slogdet(np.identity(N_S)+SNR/N_S*np.linalg.multi_dot([pinv(R_n),conjT(A_r),channel,A_t,conjT(A_t),conjT(channel),A_r]))    
        return np.log2(2.718281)*R

    def beam_sweeping(self.current_step,channels,N_t,N_r,SNR):
        channel = channels(:,:,0,current_step) # Fix the realization and get the current channel
        i_star = 0
        j_star = 0
        maximum_beam_measurement = 0
        for i_dummy in range(N_t):
            for j_dummy in range(N_r):
                beam_measurement = self.SE_computation(i_dummy,j_dummy,SNR)
                if beam_measurement > maximum_beam_measurement:
                    i_star = i_dummy
                    j_star = j_dummy
                    maximum_beam_measurement = beam_measurement
        return i_star, j_star, maximum_beam_measurement

'''
    def render(self, mode='human'):
        print('--------------------------------------------------------------')
        print('step is {}'.format(self.current_step))
        #print('first three element of state is {}'.format(self.state[0:3]))
        print('reward is {}'.format(self.reward))
        print('--------------------------------------------------------------')
        pass
'''

############################################################################################
############################################################################################
############################################################################################
############################################################################################
############################################################################################
############################################################################################
############################################################################################

