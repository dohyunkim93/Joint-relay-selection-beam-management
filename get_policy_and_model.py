import gym, os, pickle
import numpy as np

from stable_baselines import TD3,DDPG,TRPO
from stable_baselines.common.policies import MlpPolicy
from stable_baselines.ddpg.noise import NormalActionNoise, OrnsteinUhlenbeckActionNoise
from gym.spaces import Box
from DRL_hybrid_precoding import DRLHybridPrecodingEnv

###########################################################
####################CHANNEL MODEL##########################
###########################################################

current_path = os.getcwd()
Tx_Rx_channel_contents = pickle.load(open(current_path+"//16_16_Tx_to_Rx_channel_data.p","rb")) #Change the file name (directory) accordingly to the way the channel is generated
Tx_relay_channel_contents = pickle.load(open(current_path+"//16_16_Tx_to_relay_channel_data.p","rb")) #Change the file name (directory) accordingly to the way the channel is generated
relay_Rx_channel_contents = pickle.load(open(current_path+"//16_16_relay_to_Rx_channel_data.p","rb")) #Change the file name (directory) accordingly to the way the channel is generated
# channel data in .p format is a python dictionary, generated from .mat file
# it includes the channel matrix H, with size (N_r,N_t,realization,K)

###########################################################


pw_of_episode_length = 2
episode_length = 10**pw_of_episode_length

channel_contents = [Tx_Rx_channel_contents,Tx_relay_channel_contents,relay_Rx_channel_contents]
env = DRLThresholdLearningEnv(channel_contents,N_t=16,L_t=1,L_r=1,N_r=16,N_S=1,SNRdB=0,ep_length=episode_length)

#####################NOISE MODEL###########################
n_actions = env.num_actions

action_noise = NormalActionNoise(mean=np.zeros(n_actions), sigma=0.1 * np.ones(n_actions))
###########################################################

model = TRPO(MlpPolicy, env, verbose=1) #To change the function TRPO() to others, such as TD3 or DDPG, change the policy import and noise (line 5 and 6)
model.learn(total_timesteps=episode_length, log_interval=1) #module learn outputs log every episode per log interval
model.save("TRPO_DRLThresholdLearningEnv_SNR_{}dB_episode_length_1e{}".format(env.SNRdB,pw_of_episode_length))

#del model # remove to demonstrate saving and loading
#model = TD3.load("td3_customenv") #better to not del and load model for now

done = False

obs = env.reset()

action, _states = model.predict(obs)
print('current step after reset is {}'.format(env.current_step))
print('ep length after reset is {}'.format(env.ep_length))
obs, rewards, done, info = env.step(action)
print('done after reset is {}'.format(done))

# The while loop below to renders the learned policy
'''
while done==False:
    action, _states = model.predict(obs)
    #print('action shape is {}'.format(np.shape(action)))
    obs, rewards, done, info = env.step(action)
    #print(done)
    #env.render() #Enable for short episodes
'''