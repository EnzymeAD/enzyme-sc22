#!/bin/bash
for i in {64..127}
do
   echo “Enabling logical HT core $i.”
   echo 1 > /sys/devices/system/cpu/cpu${i}/online;
done

echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
