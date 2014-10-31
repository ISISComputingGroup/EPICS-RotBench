# Put the rotating bench IOC through its paces
# NB THIS ASSUMES WE ARE IN SIMULATION MODE!!!!!!!!
from epics import PV
import os
import time
from sys import exit

# Raise or lower the bench via record simulation of the FINS
def bench_rl(state):
	fins_status_sp_sim.put(state)
	time.sleep(1)
	status = fins_status.get(as_string=True)
	if state==1 and status!='RAISED':
		print 'Ooops - FINS not raising on command'
		exit(0)
	elif state==0 and status!='LOWERED':
		print 'Ooops - FINS not lowering on command'
		exit(0)
		
# Check the FINS was told to do something
def check_fins_sp(state):
	status = fins_status_sp.get(as_string=True)
	if state==1 and status!='RAISE':
		print 'FINS setpoint should be RAISE but is ' + status
		exit(0)
	elif state==0 and status!='LOWER':
		print 'FINS setpoint should be LOWER but is ' + status
		exit(0)
		
# Check the bench is in the expected state
def check_status(expected):
	status = rotb_status.get(as_string=True)
	if status!=expected:
		print 'Ooops - should be ' + expected + ' but status is ' + status
		exit(0)

# Create PVs
check_pv = PV(os.environ['MYPVPREFIX'] + 'ROTB:CHECK_HV')
current_angle_pv = PV(os.environ['MYPVPREFIX'] + 'ROTB:ANGLE')
new_angle_pv = PV(os.environ['MYPVPREFIX'] + 'ROTB:ANGLE:SP')
fins_status_sp = PV(os.environ['MYPVPREFIX'] + 'BENCH:MOVE:SP')
fins_status_sp_sim = PV(os.environ['MYPVPREFIX'] + 'BENCH:SIM:STATUS')
fins_status = PV(os.environ['MYPVPREFIX'] + 'BENCH:STATUS')
rotb_status = PV(os.environ['MYPVPREFIX'] + 'ROTB:STATUS')

# Ensure motor will drive
motor_spmg = PV(os.environ['MYPVPREFIX'] + 'MOT:MTR0401.SPMG')
motor_spmg.put("Go")

# Ensure FINS is in simulation mode
fins_sim = PV(os.environ['MYPVPREFIX'] + 'BENCH:SIM')
fins_sim.put(1)

# Ensure the bench is lowered at the start
bench_rl(0)
print 'Fins lowered'

# Check the rotating bench IOC is ready
status = rotb_status.get(as_string=True)
if status=='Init':
	print 'Ooops - RotBench still initialing'
	print 'Make sure GALIL_01, FINS_01, HVCAEN_SIM are started'
	exit(0)
elif status!='Done':
	print 'Ooops - RotBench is in state: ' + status
	exit(0)
else:
	print 'RotBench ready'

# Turn off HV checking
check_pv.put(0)

# Decide where to go
current_angle = current_angle_pv.get()
new_angle = current_angle + 3
if new_angle > 10:
	new_angle = current_angle - 3

print 'Driving from ' + str(current_angle) + ' to ' + str(new_angle) + ' ignoring hv'

# Go
new_angle_pv.put(new_angle)

# Should be raising
check_status('Raising_bench')
print 'Raising...'

# Check the FINS got the message
check_fins_sp(1)

# Wait for it to raise
time.sleep(25)

# Should be raising
status = rotb_status.get(as_string=True)
if status=='Raising_bench':
	# Tell the bench to raise
	bench_rl(1)
	check_status('Moving')
	print 'Moving...'
elif status=='Moving':
	print 'Interesting - bench has raised itself'
else:
	print 'Ooops - should still be Raising but status is ' + status
	exit(0)

# Moving
status = rotb_status.get(as_string=True)
while status=='Moving':
	time.sleep(5)
	current_angle = current_angle_pv.get()
	print 'Angle: ' + str(current_angle)
	status = rotb_status.get(as_string=True)
	
# Lowering
check_status('Lowering')
print 'Lowering...'
	
# 
current_angle = current_angle_pv.get()
if abs(current_angle - new_angle)>0.1:
	print 'Ooops - angle should be ' + new_angle + ' but is ' + current_angle
	exit(0)

# Check the FINS got the message
check_fins_sp(0)

# Wait for it to lower
time.sleep(25)

# Should still be lowering
status = rotb_status.get(as_string=True)
if status=='Lowering':
	# Tell the bench to lower
	bench_rl(0)
	check_status('Done')
	print 'Done!'
elif status=='Done':
	print 'Interesting - bench has lowered itself'
else:
	print 'Ooops - should still be Lowering but status is ' + status
	exit(0)
