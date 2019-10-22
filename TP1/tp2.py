import torch
from torch import nn
import math
import matplotlib.pyplot as pyplot

#cours TP2

print(torch.__version__)

class MyMLP(nn.Module):
    def __init__(self) :
        super().__init__()
        #nm.Linear : [nb entrées, nb neurones]
        self.in_to_hidden = nn.Linear(1,16)
        self.hidden_to_out = nn.Linear(16,1)
    
    def forward(self,x):
        h = self.in_to_hidden(x)
        #add non linearity 
        h = nn.functional.relu(h)
        return self.hidden_to_out(h)
    
if __name__ == '__main__':

    #données d'entrainement
    data = torch.linspace(0,2*math.pi,1000).unsqueeze(1)
    #valeur réf
    label = torch.sin(data)
    #init réseau
    mlp = MyMLP()
    pyplot.ion()
    fig, ax = pyplot.subplots()
    #recupérer gradient et regle MAJ pour weights

    optim = torch.optim.SGD(mlp.parameters(),lr=0.01)

    dataset = torch.nn.utils.TensorDataset(data,label)

    loader = torch.nn.utils.DataLoader(dataset,batch_size = 32)

    # parcours de la base avec échantillon (x) et label (sin)
    # objectif : diminuer l'erreur entre (x) et (sin) en appellant forward
    prv_loss = None
    for it in range(100):
        db_loss = 0
        for i, (x, sin_x) in enumerate(loader):
            out = mlp(x)
            #print(x,out.size(),sin_x.size())

            #calcul de l'erreur
            loss = nn.functional.mse_loss(out,sin_x)
            db_loss += loss.item()
            optim.zero_grad()
            loss.backward()
            optim.step()
        if prv_loss is not None:
            ax.plot([it-1,it],[prv_loss,loss.item(),loss/len(dataset)],'r')
            pyplot.pause(0.001)
        prv_loss = loss /len(dataset)

    pyplot.iof()
    fi, ax = pylot.subplot()
    x = torch.linspace(0,4*math.pi,2000)
    ax.plot(x.tolist(), torch.sin(x).tolist())
    ax.plot(x.tolist(),mlp(x.unsqueeze(1)).squeeze(1).tolist())
    
        
    # for it in range(1000)
    #     x = data[torch.randint((0,1000,(1,)))]

    #ttravail : remplacer Q tabulaire par réseau de neurone. on prend s en entrée (x,y) et espace action en sortie 
    #collecter batch pour mettre à jour (plusieurs step) (s,a,r,done,s')
    #update : dans la memory piocher n transition aléatoirement 