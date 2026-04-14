PROGRAM PLC4_PRESS

VAR
    cycle_time : REAL := 30.0;
    parts_per_hour : REAL := 100.0;

    porosity_flag : BOOL := FALSE;
    fill_quality : REAL := 0.95;

    pressure_alarm : BOOL := FALSE;

    hydraulic_energy : REAL := 200.0;

    press_idle_time : REAL := 0.0;

    press_load : REAL := 70.0;
    die_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

VAR_EXTERNAL
    reg_cycle_time_x10 : UINT;
    reg_parts_per_hour_x10 : UINT;
    reg_porosity_flag : UINT;
    reg_fill_quality_x1000 : UINT;
    reg_pressure_alarm : UINT;
    reg_hydraulic_energy_x10 : UINT;
    reg_press_idle_time_x10 : UINT;
    reg_press_load_x10 : UINT;
    reg_die_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 23) MOD 100) / 100.0;
tick := tick + 1;

cycle_time := 25.0 + (rand * 10.0);
parts_per_hour := 3600.0 / cycle_time;

fill_quality := 0.9 + (rand * 0.1);

IF rand < 0.02 THEN
    porosity_flag := TRUE;
END_IF;

press_load := 60.0 + (rand * 30.0);

IF press_load > 85.0 THEN
    pressure_alarm := TRUE;
END_IF;

hydraulic_energy := press_load * 2.5;

die_health := die_health - 0.0005;

(* Export live values to Modbus holding registers %MW0.. *)
reg_cycle_time_x10 := REAL_TO_UINT(cycle_time * 10.0);
reg_parts_per_hour_x10 := REAL_TO_UINT(parts_per_hour * 10.0);
IF porosity_flag THEN
    reg_porosity_flag := 1;
ELSE
    reg_porosity_flag := 0;
END_IF;
reg_fill_quality_x1000 := REAL_TO_UINT(fill_quality * 1000.0);
IF pressure_alarm THEN
    reg_pressure_alarm := 1;
ELSE
    reg_pressure_alarm := 0;
END_IF;
reg_hydraulic_energy_x10 := REAL_TO_UINT(hydraulic_energy * 10.0);
reg_press_idle_time_x10 := REAL_TO_UINT(press_idle_time * 10.0);
reg_press_load_x10 := REAL_TO_UINT(press_load * 10.0);
reg_die_health_x10 := REAL_TO_UINT(die_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_cycle_time_x10 AT %MW0 : UINT;
      reg_parts_per_hour_x10 AT %MW1 : UINT;
      reg_porosity_flag AT %MW2 : UINT;
      reg_fill_quality_x1000 AT %MW3 : UINT;
      reg_pressure_alarm AT %MW4 : UINT;
      reg_hydraulic_energy_x10 AT %MW5 : UINT;
      reg_press_idle_time_x10 AT %MW6 : UINT;
      reg_press_load_x10 AT %MW7 : UINT;
      reg_die_health_x10 AT %MW8 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC4_PRESS;
  END_RESOURCE
END_CONFIGURATION
