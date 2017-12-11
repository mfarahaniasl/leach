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
#from postprocessZ import *
import postprocessZ
import time

t = Tossim([])
r = t.radio();

##########
#TOPOLOGY
##########
f = open("Topologies/topo12perfect.txt", "r")

lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if (s[0] == "gain"):
      #if (((int(s[1])) <= 30) & ((int(s[2])) <= 30)):
        print " ", s[1], " ", s[2], " ", s[3];
        r.add(int(s[1]), int(s[2]), float(s[3]));
	numNodes=int(s[1]);
print "numnodes ",int(s[1]);

######################
#NOISE TRACE & BOOTING
######################
noise = open("Noise/meyer-heavy-short.txt", "r")
#noise = open("Noise/meyer-heavy.txt", "r")
lines = noise.readlines()
for line in lines:
  str = line.strip()
  if (str != ""):
    val = int(str)
    for i in range(0, numNodes+1):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(0, numNodes+1):
  print "Creating noise model for ",i;
  t.getNode(i).createNoiseModel();

for i in range(0, numNodes+1):
  #bootTime=randint(1000,20000) * 1;
  bootTime=i * 2351217 + 23542399;
  t.getNode(i).bootAtTime(bootTime);
  print "Boot Time for Node ",i, ": ",bootTime; 

#########
#CHANNELS
#########
bla = open("result/Energy.txt", "w");
resTossimPacket = open("result/TossimPacket.txt", "w");

t.addChannel("ENERGY_HANDLER", bla); 
t.addChannel("TossimPacket", resTossimPacket); 

t.addChannel("TESTLEDS", sys.stdout);

#########
#Load Mote List
#########
motes = []
batteryLevel = []
for mote in range(0, numNodes+1):
  motes.append(t.getNode(mote))
  batteryLevel.append(motes[mote].getVariable("BatteryC.level"))

##########
#EXEC LOOP
##########
lineIndex = 0
lineIndex_last = 0
postprocessZ.battery_total_charge = 0.740741 # mAh
postprocessZ.start_time = time.time()
postprocessZ.trace = open("result/Energy.txt","r")
postprocessZ.powercurses = 1
postprocessZ.initstate()

lineno = 1
l = postprocessZ.trace.readline()

t.runNextEvent();
simtime=t.time();
            # 1,000,000,000,000 = 100 seconds
while (simtime + 100000000000 > t.time()):
  t.runNextEvent();
  l = postprocessZ.trace.readline()

  with open('result/Energy.txt') as f:
    lineIndex = sum(1 for _ in f)
  
  if lineIndex_last != lineIndex:
    #print "Now", lineIndex, "Last=", lineIndex_last
    #l=trace.readline()
    for line in range (lineIndex_last, lineIndex, 1):
      #print l
      postprocessZ.handle_event(l)
      lineno += 1
      l = postprocessZ.trace.readline()
    for mote in range(postprocessZ.maxseen+1):
      batteryLevel[mote].setData(postprocessZ.battery[mote]/postprocessZ.battery_total_charge*100)
    lineIndex_last = lineIndex

if postprocessZ.summary:
  postprocessZ.print_summary()
  print "Simulated seconds: %.1f" % (postprocessZ.maxtime/postprocessZ.simfreq)
  print "Real seconds: %.1f" % (time.time()-postprocessZ.start_time)

