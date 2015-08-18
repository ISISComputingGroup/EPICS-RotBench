#!../../bin/windows-x64/rotBench

## You may have to change RotatingBench to something else
## everywhere it appears in this file

# Increase this if you get <<TRUNCATED>> or discarded messages warnings in your errlog output
errlogInit2(65536, 256)

< envPaths

cd ${TOP}

## Register all support components
dbLoadDatabase "dbd/rotBench.dbd"
rotBench_registerRecordDeviceDriver pdbbase

##ISIS## Run IOC initialisation 
< $(IOCSTARTUP)/init.cmd

## Load record instances

##ISIS## Load common DB records 
< $(IOCSTARTUP)/dbload.cmd

## Load our record instances
dbLoadRecords("db/bench.db","P=$(MYPVPREFIX),R=ROTB:,M=MOT:MTR0401")

##ISIS## Stuff that needs to be done after all records are loaded but before iocInit is called 
< $(IOCSTARTUP)/preiocinit.cmd

cd ${TOP}/iocBoot/${IOC}
iocInit

## Start any sequence programs
seq(larmor_rotation,"P=$(MYPVPREFIX),R=ROTB:,HV1=CAEN:hv0:0:0:,HV2=CAEN:hv0:0:1:,HV3=CAEN:hv0:1:0:,HV4=CAEN:hv0:1:1:,V=TPG300:PRESSURE_A1,M=MOT:MTR0401,Q=BENCH:")

##ISIS## Stuff that needs to be done after iocInit is called e.g. sequence programs 
< $(IOCSTARTUP)/postiocinit.cmd
