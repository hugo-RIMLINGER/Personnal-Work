from gridworld import GridWorld
import torch
import numpy as np
import getch
import time
import random

import matplotlib.pyplot as plt

#main for TP1

def evaluate_pi(grid, pi, T=1000):
    s = grid.reset()
    done = False
    c = 0
    for _ in range(T):
        s, r, done = grid.step(s, pi[s])
        c += r
        if done:
            break
    return c

def dynamic_programming(grid, T=50):
    t = grid.transition_tensor
    r = grid.reward_tensor
    s0 = grid.reset()

    pi = torch.randint(0, grid.action_space_size, (grid.state_space_size, 1))
    V_pi = torch.zeros((grid.state_space_size, 1))

    s0_values = []

    for i in range(T):
        print("\rprogress={}%".format(int(100 * i / T)), end='')
        V_pi = (t * (r + 0.9 * V_pi.view(1, 1, grid.state_space_size))).sum(2).gather(1, pi)
        pi = (t * (r + 0.9 * V_pi.view(1, 1, grid.state_space_size))).sum(2).argmax(1, keepdim=True)
        s0_values.append(V_pi[s0])

    print()

    plt.plot(range(T), s0_values)
    plt.show()

    return pi

def epsilon_greedy_action(e, Q, s,grid):
    n = random.random()
    if n < e:
        a = torch.randint(0,grid.action_space_size,(1,))
    else: 
        a = Q[s].argmax()
    return a

def generate_episode(grid, pi, n):
    s = grid.reset()
    for _ in range(n):
        s, r, done = grid.step(s, pi[s])

def monte_carlo(g):
    pass

def q_value(g):
    n_a = g.action_space_size
    n_s = g.state_space_size
    lt = 0.1

    Q = torch.zeros((n_s, n_a), dtype=torch.uint8)

    for _ in range(1000):
        s = g.reset()
        prev_s = s
        for i in range(1000):

            a = epsilon_greedy_action(0.1, Q, s,g)
            s, r, done = g.step(a)
            error = int(r + max(Q[s]) - int(Q[prev_s][a]))
            Q[s][a] += lt * error
            prev_s = s
            if done == True:
                print(i)
                break


    Q = torch.zeros((n_s, n_a))
    # Remplacer Q par un MLP (domain state) => (|A|) (prend un état et renvoie une action)
    # domain state = 2 pour gridworld basic (largeur, hauteur : 2 dimensions)
    for it in range(n_it):
        s = g.reset()
        done = False
        td_errors = []
        
        # Gather samples
        for t in range(max_t):
            a = Q[s.argmax() if torch.rand((1,)) < epsilon else torch.randint(0, n_a, n_s, (1,))]
            s_prime, r, done = g.step(a)
            target = 0 if done else Q[s_prime].max()
            target = r + discount * target
            td_errors.append((s, a, target - Q[s, a]))
            s = s_prime
            if done:
                break
        
        # Update Q

        # Il faut accumuler les échantillon (s, a, r, done, s_prime)
        # Composer un mini batch et le donner à un mse_loss puis backprog et update Q
        # mse_loss(Q(s)[a], target)
        # target: deux cas
        #   si état final : target = 0
        #   sinon : Q(s_prime).max() + r
        for s, a, err in td_errors:
            Q[s, a] += lt * err
        
        # Update epsilon


    print(Q)
    return Q    

if __name__ == '__main__':
    grid = GridWorld(3, 2)
    grid.add_start(1, 1)
    # grid.add_goal(7, 7)
    # grid.add_room(2, 2, 6, 6)
    #grid.add_room(9, 2, 14, 7)
    
    print("Training...")
    pi = dynamic_programming(grid)
    print("Training done")
    
    s = grid.reset()
    done = False
    while not done:
        s, r, done = grid.step(s, pi[s])
        time.sleep(0.5)
        print("r:", r, ", s:", s, "a:", pi[s])
        print(grid)
        #print(grid)
    #interactive(grid)
