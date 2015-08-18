program larmor_rotation

float angle_sp;
assign angle_sp to "{P}{R}ANGLE:SP";
monitor angle_sp;

float angle_sp_rbv;
assign angle_sp_rbv to "{P}{R}ANGLE:SP:RBV";

short status;
assign status to "{P}{R}STATUS";

short lift_status;
assign lift_status to "{P}{Q}STATUS";
monitor lift_status;

short lift_status_sp;
assign lift_status_sp to "{P}{Q}MOVE:SP";

float delay_raise;
assign delay_raise to "{P}{R}DELAY:RAISE";
monitor delay_raise;

float delay_lower;
assign delay_lower to "{P}{R}DELAY:LOWER";
monitor delay_lower;

short check_hv;
assign check_hv to "{P}{R}CHECK_HV";
monitor check_hv;

short hv_status1;
assign hv_status1 to "{P}{HV1}pwonoff";
monitor hv_status1;
short need_powerup;

short hv_status2;
assign hv_status2 to "{P}{HV2}pwonoff";
monitor hv_status2;
/*short need_powerup;*/

short hv_status3;
assign hv_status3 to "{P}{HV3}pwonoff";
monitor hv_status3;
/*short need_powerup;*/

short hv_status4;
assign hv_status4 to "{P}{HV4}pwonoff";
monitor hv_status4;
/*short need_powerup;*/

float hv_delay_on;
assign hv_delay_on to "{P}{R}HV:DELAY:ON";
monitor hv_delay_on;

float hv_delay_off;
assign hv_delay_off to "{P}{R}HV:DELAY:OFF";
monitor hv_delay_off;

float motor_sp;
assign motor_sp to "{P}{M}";

short motor_done;
assign motor_done to "{P}{M}.DMOV";
monitor motor_done;

ss rotation_states {
	state init {
		when () {
			status = 0; /* nothing to do */
			pvPut(status);
			angle_sp_rbv = angle_sp;
			pvPut(angle_sp_rbv);
			printf("->Done State=%d, Angle_sp=%f, angle_sp_rbv=%f\n", status, angle_sp, angle_sp_rbv);
		} state done_move
	}
	
	state done_move {
		/* Start move by powering down the CAEN */
		when ( angle_sp!=angle_sp_rbv && check_hv==1 && hv_status1==1 ) {
			angle_sp_rbv = angle_sp;
			pvPut(angle_sp_rbv);
		
			status = 1; /* CAEN powering down */
			pvPut(status);
			need_powerup = hv_status1;
			hv_status1 = 0;
			pvPut(hv_status1);
			hv_status2 = 0;
			pvPut(hv_status2);
			hv_status3 = 0;
			pvPut(hv_status3);
			hv_status4 = 0;
			pvPut(hv_status4);
			printf("->PD State=%d, Angle_sp=%f, angle_sp_rbv=%f, caen_status=%d\n", status, angle_sp, angle_sp_rbv, hv_status1);
		} state powering_down

		/* Start move. No need to power down CAEN so go straight to lift */
		when ( angle_sp!=angle_sp_rbv && (check_hv==0 || hv_status1==0) ) {
			angle_sp_rbv = angle_sp;
			pvPut(angle_sp_rbv);
			need_powerup = 0;
		
			status = 2; /* Lifting */
			pvPut(status);
			lift_status_sp = 1;
			pvPut(lift_status_sp);
			printf("->Lifting State=%d, Angle_sp=%f, angle_sp_rbv=%f, lift_status=%d\n", status, angle_sp, angle_sp_rbv, lift_status_sp);
		} state lifting
	}
	
	state powering_down {
		when ( delay(hv_delay_off) ) {
			status = 2; /* Lifting */
			pvPut(status);
			lift_status_sp = 1;
			pvPut(lift_status_sp);
			printf("->Lifting(2) State=%d, lift_status=%d\n", status, lift_status_sp);
		} state lifting
	}
	
	state lifting {
		when ( delay(delay_raise) && lift_status==1 ) {
			status = 3; /* Moving */
			pvPut(status);
			motor_sp = angle_sp_rbv;
			pvPut(motor_sp);
			printf("->Moving State=%d, angle=%f\n", status, motor_sp);
		} state moving
	}
	
	state moving {
		when ( delay(1) && motor_done==1 ) {
			status = 4; /* Lowering */
			pvPut(status);
			lift_status_sp = 0;
			pvPut(lift_status_sp);
			printf("->Lowering State=%d, lift_status=%d\n", status, lift_status);
		} state lowering
	}
	
	state lowering {
		when ( delay(delay_lower) && need_powerup==1 && lift_status==0 ) {
			status = 5; /* CAEN powering up */
			pvPut(status);
			hv_status1 = 1;
			pvPut(hv_status1);
			hv_status2 = 1;
			pvPut(hv_status2);
			hv_status3 = 1;
			pvPut(hv_status3);
			hv_status4 = 1;
			pvPut(hv_status4);
			printf("->PU State=%d, caen_status=%d\n", status, hv_status1);
		} state powering_up
		
		when ( need_powerup==0 && delay(delay_lower) && lift_status==0 ) {
			status = 0; /* Done */
			pvPut(status);
			printf("->Done State=%d\n", status);
		} state done_move
	}
	
	state powering_up {
		when ( delay(hv_delay_on) ) {
			status = 0; /* Done */
			pvPut(status);
			printf("->Done(2) State=%d\n", status);
		} state done_move
	}
}
