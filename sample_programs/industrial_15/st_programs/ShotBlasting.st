PROGRAM PLC7_SHOTBLAST

VAR
    cycle_time : REAL := 60.0;

    surface_cleanliness : REAL := 0.95;

    vibration_alarm : BOOL := FALSE;

    media_usage : REAL := 5.0;

    jam_time : REAL := 0.0;

    turbine_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := DINT_TO_REAL((tick * 37) MOD 100) / 100.0;
tick := tick + 1;

surface_cleanliness := 0.9 + (rand * 0.1);

IF rand < 0.01 THEN
    vibration_alarm := TRUE;
END_IF;

media_usage := 4.0 + (rand * 2.0);

turbine_health := turbine_health - 0.0003;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC7_SHOTBLAST;
  END_RESOURCE
END_CONFIGURATION
