import torch
import torch.nn as nn
import random 
from grid import GridWorld
import tqdm
import collections
from matplotlib import pyplot as plt

# grille 6x6 parameters 
DIM_INPUT = 2
DIM_HIDDEN = 16
DIM_OUTPUT = 4
MAX_ITER = 15000
MEM_SIZE = 500
BATCH_SIZE = 64
DISCOUNT_FACTOR = 0.5
FREEZE_PERIOD = 20
T_MAX = 300
PLOT = True

# DIM_INPUT = 2
# DIM_HIDDEN = 16
# DIM_OUTPUT = 4
# MAX_ITER = 1000
# MEM_SIZE = 500
# BATCH_SIZE = 32
# DISCOUNT_FACTOR = 0.5
# FREEZE_PERIOD = 20
# T_MAX = 100
# PLOT = True

# DIM_INPUT = 2
# DIM_HIDDEN = 16
# DIM_OUTPUT = 4
# MAX_ITER = 10000
# MEM_SIZE = 700
# BATCH_SIZE = 32
# DISCOUNT_FACTOR = 0.5
# FREEZE_PERIOD = 20
# T_MAX = 400
# PLOT = True

#Implementation of DQN algo

class NeuralNetwork(nn.Module):

    def __init__(self,height = 10,width = 10):
        super().__init__()
        self.in_to_hidden = nn.Linear(DIM_INPUT,DIM_HIDDEN)
        self.hidden_to_hidden = nn.Linear(DIM_HIDDEN,DIM_HIDDEN)
        self.hidden_to_out = nn.Linear(DIM_HIDDEN,DIM_OUTPUT)
        self.fig = plt.figure('cumul total')
    
    def forward(self,data):
        h = self.in_to_hidden(data)
        h = nn.functional.relu(h)
        h = self.hidden_to_hidden(h)
        return self.hidden_to_out(h)
    
    def sample_action(self,state,Q_value,epsilon):
        if random.random() < epsilon:
            return torch.randint(0,3,(1,))
        else:
            return Q_value(torch.from_numpy(state).float().unsqueeze(0)).argmax(1).item()

    def sample_trajectory(self,grid,replay_memory,Q_value,epsilon):
        state = torch.zeros((1,0))
        next_state = torch.zeros((1,0))
        state = grid.reset()
        cumul = 0
        
        for _ in range(T_MAX):
            action = self.sample_action(state,Q_value,epsilon)
            next_state,reward,done = grid.step(int(action))
            replay_memory.append((state,action,reward,next_state,done))
            state = next_state
            cumul += reward
            if done:
                break
        grid.terminate()
        return cumul

    def train(self,grid,Q_value,Q_value_target):
        optim = torch.optim.SGD(Q_value.parameters(),lr = 0.001)
        replay_memory = collections.deque(maxlen = MEM_SIZE)
        epsilon = 0.90
        cumulTot = []
        

        with tqdm.trange(MAX_ITER) as progress_bar: 
            
            for it in progress_bar:
                totloss = 0
                cumul = self.sample_trajectory(grid,replay_memory,Q_value,epsilon)

                if PLOT: 
                    if it%5 == 0:
                        cumulTot.append(cumul)
                    

                n = len(replay_memory)

                if n > BATCH_SIZE : 
                    indices = list(range(n))
                    random.shuffle(indices)
                    for b in range(n//BATCH_SIZE):
                        batch_state,batch_action,batch_reward,batch_next_state,batch_done = zip(*(replay_memory[indices[i]] for i in indices[b*BATCH_SIZE:(b+1)*BATCH_SIZE]))
                        batch_state = torch.tensor(batch_state).float()
                        batch_action = torch.tensor(batch_action).unsqueeze(1)
                        batch_reward = torch.tensor(batch_reward).unsqueeze(1)
                        batch_next_state = torch.tensor(batch_next_state).float()
                        batch_done = torch.tensor(batch_done).unsqueeze(1)

                        # print(batch_state,batch_action,batch_reward,batch_next_state,batch_done)

                        batch_target = batch_reward + DISCOUNT_FACTOR * Q_value_target(batch_next_state).max(1,keepdim = True)[0]
                        batch_target[batch_done] = 0
                        batch_qValue = Q_value(batch_state).gather(1,batch_action)

                        loss =  nn.functional.mse_loss(batch_qValue,batch_target)
                        totloss += loss.item()
                        optim.zero_grad()
                        loss.backward()
                        optim.step()

                    progress_bar.set_postfix(loss = totloss/(n//BATCH_SIZE), cumul = cumul)
                if it % FREEZE_PERIOD == FREEZE_PERIOD - 1:
                    Q_value_target.load_state_dict(Q_value.state_dict())
                epsilon = 1 - it / MAX_ITER
        return cumulTot


if __name__ == '__main__':
    height = 8
    width = 8
    grid = GridWorld(height,width)
    grid.add_start(1,1)
    grid.add_goal(height,width)
    # state = torch.full((1,0),1,dtype = torch.float)
    # state = torch.tensor(grid.reset(),dtype = torch.float).unsqueeze(0)
    # print(state)

    Q_value = NeuralNetwork(height,width)
    # print(Q_value(state))
    target_q_value = NeuralNetwork(height,width)
    target_q_value.load_state_dict(Q_value.state_dict())
    plt.ion()
    cumulTot = Q_value.train(grid,Q_value,target_q_value)
    plt.plot(cumulTot,'r')
    plt.xlabel('nb episode/5')
    plt.ylabel('cumul rewards')
    Q_value.fig.savefig('8x8 grid DQN')




    