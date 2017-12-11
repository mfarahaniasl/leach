#/bin/bash
#python MySimulation.py #--duration 300
#python postprocessZ.py --capacity 0.046296 result/Energy.txt
python postprocessZ.py --capacity  0.185184 result/Energy.txt
#python postprocessZ.py --powercurses --capacity 0.046296 result/Energy.txt > result/EnergyPowerCurses.txt
#cd powercurses/ && make && ./powercurses 11 < EnergyPowerCurses.txt
