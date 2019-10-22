import torch
import numpy as np
import itertools as it
import math

 #define the state of the world
class State:
    DIRTY = 0
    CLEAN = 1

    def __init__(self, x, y, clean_mask, grid_width):
        self.x = x
        self.y = y
        self.clean_mask = clean_mask
        self.grid_width = grid_width
        self.mask_index = x + y * grid_width
    
    def is_clean(self):
        return self.clean_mask[self.mask_index] == State.CLEAN

class GridWorld:
    class CellType:
        FREE = 255
        CLEAN = 254
        WALL = 0
        DIRTY = 50
        STRT = 100

    class Action:
        UP=0
        LEFT=1
        DOWN=2
        RIGHT=3
        CLEAN=4

    def __init__(self, width=10, height=10, move_cost=1, clean_reward=10):
        self.width = width
        self.height = height
        self.move_cost = move_cost
        self.clean_reward = clean_reward

        self.cells = torch.full((height+2, width+2), GridWorld.CellType.DIRTY, dtype=torch.uint8)
        self.add_room(0, 0, height + 1, width + 1)

        self.states = [None for _ in range(self.state_space_size)]

        masks = [torch.Tensor(x) \
            for x in list(it.product([0, 1], repeat=width * height))]
        
        i = 0
        for x in range(self.width):
            for y in range(self.height):
                for mask in masks:
                    s = State(x, y, mask, width)
                    self.states[i] = s
                    i += 1

    def add_horizontal_wall(self, at_y, from_x, to_x):
        self.cells[at_y,from_x:to_x+1] = GridWorld.CellType.WALL

    def add_vertical_wall(self, at_x, from_y, to_y):
        self.cells[from_y:to_y+1, at_x] = GridWorld.CellType.WALL

    def add_room(self, top, left, bot, right):
        self.add_horizontal_wall(top, left, right)
        self.add_horizontal_wall(bot, left, right)
        self.add_vertical_wall(left, top+1, bot-1)
        self.add_vertical_wall(right, top+1, bot-1)

    def add_start(self, at_x, at_y):
        self.cells[at_y, at_x] = GridWorld.CellType.STRT

    def __str__(self):
        if hasattr(self, "agent_x"):
            content = self.cells.clone()
            content[self.agent_y, self.agent_x] = 250
        else:
            content = self.cells
        return '\n'.join(' '.join("{}" for x in range(self.width+2)) for y in range(self.height+2)).format(*({
            GridWorld.CellType.WALL: "X",
            GridWorld.CellType.DIRTY: "_",
            GridWorld.CellType.STRT: "o",
            250: "+"
            }.get(c.item(), " ") for c in content.view(-1)))

    @property
    def state_space_size(self):
        return self.width * self.height * int(math.pow(2, self.width * self.height))

    @property
    def action_space_size(self):
        return 5

    def find_state(self, x, y, clean_mask):
        for i, s in enumerate(self.states):
            if s.x == x and s.y == y and torch.all(torch.eq(s.clean_mask, clean_mask)):
                return i
        print("Can't find ", x, y, clean_mask)

    @property
    def transition_tensor(self):
        if not hasattr(self, "_t"):
            self._t = torch.zeros((self.state_space_size, self.action_space_size, self.state_space_size))
            for i, s in enumerate(self.states):

                # Clean transition
                if not s.is_clean():
                    clean_mask = s.clean_mask.clone()
                    clean_mask[s.mask_index] = 1
                    self._t[i, GridWorld.Action.CLEAN, self.find_state(s.x, s.y, clean_mask)] = 1
                else:
                    self._t[i, GridWorld.Action.CLEAN, i] = 1

                # Up transition
                if self.cells[s.y, s.x + 1] == GridWorld.CellType.WALL:
                    self._t[i, GridWorld.Action.UP, i] = 1
                else:
                    self._t[i, GridWorld.Action.UP, self.find_state(s.x, s.y - 1, s.clean_mask)] = 1

                # Down transition
                if self.cells[s.y + 2, s.x + 1] == GridWorld.CellType.WALL:
                    self._t[i, GridWorld.Action.DOWN, i] = 1
                else:
                    self._t[i, GridWorld.Action.DOWN, self.find_state(s.x, s.y + 1, s.clean_mask)] = 1

                # Left transition
                if self.cells[s.y+1,s.x] == GridWorld.CellType.WALL:
                    self._t[i, GridWorld.Action.LEFT, i] = 1
                else:
                    self._t[i, GridWorld.Action.LEFT, self.find_state(s.x - 1, s.y, s.clean_mask)] = 1

                # Right transition
                if self.cells[s.y+1,s.x+2] == GridWorld.CellType.WALL:
                    self._t[i, GridWorld.Action.RIGHT, i] = 1
                else:
                    self._t[i, GridWorld.Action.RIGHT, self.find_state(s.x + 1, s.y, s.clean_mask)] = 1

        return self._t

    @property
    def reward_tensor(self):
        if not hasattr(self, "_r"):
            self._r = torch.full((self.state_space_size, self.action_space_size, self.state_space_size), -self.move_cost)
            for i, s in enumerate(self.states):
                if not s.is_clean():
                    clean_mask = s.clean_mask.clone()
                    clean_mask[s.mask_index] = 1
                    self._r[i, GridWorld.Action.CLEAN, self.find_state(s.x, s.y, clean_mask)] = self.clean_reward
        return self._r

    def reset(self):
        self.agent_y, self.agent_x = 1, 1
        return self.find_state(0, 0, torch.zeros((self.width * self.height)))

    def step(self, i, action):
        s = self.states[i]
        clean_mask = s.clean_mask.clone()

        if action == GridWorld.Action.UP \
                and self.cells[self.agent_y - 1, self.agent_x] != GridWorld.CellType.WALL:
                    self.agent_y -= 1
        elif action == GridWorld.Action.LEFT \
                and self.cells[self.agent_y, self.agent_x - 1] != GridWorld.CellType.WALL:
                    self.agent_x -= 1
        elif action == GridWorld.Action.DOWN \
                and self.cells[self.agent_y + 1, self.agent_x] != GridWorld.CellType.WALL:
                    self.agent_y += 1
        elif action == GridWorld.Action.RIGHT \
                and self.cells[self.agent_y, self.agent_x + 1] != GridWorld.CellType.WALL:
                    self.agent_x += 1

        reward = -self.move_cost

        if action == GridWorld.Action.CLEAN and self.cells[self.agent_y, self.agent_x] != GridWorld.CellType.CLEAN:
            self.cells[self.agent_y, self.agent_x] = GridWorld.CellType.CLEAN
            reward += self.clean_reward
            clean_mask[s.mask_index] = 1

        new_state = self.find_state(self.agent_x - 1, self.agent_y - 1, clean_mask)

        done = False
        if torch.all(torch.eq(s.clean_mask, torch.ones((self.width * self.height)))):
            done = True
        
        return new_state, reward, done
