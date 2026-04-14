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

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC4_PRESS;
  END_RESOURCE
END_CONFIGURATION
