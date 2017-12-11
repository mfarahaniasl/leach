# TOSSIM python script for the simulation of RadioCountToLeds in a network,
# producing the PowerTOSSIM-Z energy trace for the ENERGY_HANDLER channel 
# in Simulations/Energy.txt.
# By default the simulation runs for 100 seconds.
# Topologies for the network of nodes are available under folder Topologies/
# with the form: node1  node2  gain
# Also the meyer_heavy noise file from TOSSIM is employed which is a list of 
# noise values taken from the meyer library at Berkeley. 
#
# * @author Ricardo Simon Carbajo <carbajor{tcd.ie}>
# * @date   Sept 18 2007 
# * Computer Science
# * Trinity College Dublin

import sys
sys.path.append('../')

from random import *
from TOSSIM import *
t = Tossim([])
r = t.radio();

##########
#TOPOLOGY
##########
f = open("Topologies/linkgain.out", "r") #linkgain.out  #topo12inGrid	#topo12perfect
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if (s[0] == "gain"):
      #if (((int(s[1])) <= 30) & ((int(s[2])) <= 30)):
        #print " ", s[1], " ", s[2], " ", s[3];
        r.add(int(s[1]), int(s[2]), float(s[3]));
        numNodes=int(s[1]);
print "numnodes ",int(s[1])+1;

######################
#NOISE TRACE & BOOTING
######################
noise = open("Noise/meyer-heavy-short.txt", "r")
#noise = open("Noise/noise.txt", "r")   #meyer-heavy	#meyer-heavy-short
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(0, numNodes+1):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(0, numNodes+1):
  #print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel();

print "All node created";

for i in range(0, numNodes+1):
  #bootTime=randint(1000,20000) * 1;
  bootTime=i * 2351217 + 23542399;
  t.getNode(i).bootAtTime(bootTime);
  #print "Boot Time for Node ",i, ": ",bootTime; 
print "All node booted";

#########
#CHANNELS
#########
bla = open("result/Energy.txt", "w");
resDebugApp = open("result/DebugApp.txt", "w");
#smac = open("result/SMAC.txt", "w");
graph = open("result/graph.txt", "w");

t.addChannel("ENERGY_HANDLER", bla); 
t.addChannel("DebugApp", resDebugApp); 
#t.addChannel("TossimPacketModelC", smac); 
t.addChannel("DebugGraph",graph);
print "Channels added";

##########
#EXEC LOOP
##########

t.runNextEvent();
simtime = t.time()
time_mul=10000000000
            # 10,000,000,000 = 1 seconds
#print simtime;
while ((simtime + ( 500*time_mul)) > t.time()):
  t.runNextEvent();

print "Simulation Ended";

