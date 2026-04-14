PROGRAM PLC3_DEGASS

VAR
    treatment_cycle_time : REAL := 60.0;

    gas_content_level : REAL := 0.02;

    gas_leak_alarm : BOOL := FALSE;

    gas_consumption : REAL := 10.0;

    idle_time : REAL := 0.0;

    rotor_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := DINT_TO_REAL((tick * 19) MOD 100) / 100.0;
tick := tick + 1;

gas_content_level := 0.01 + (rand * 0.02);

IF rand < 0.005 THEN
    gas_leak_alarm := TRUE;
ELSE
    gas_leak_alarm := FALSE;
END_IF;

gas_consumption := 8.0 + (rand * 4.0);

rotor_health := rotor_health - 0.0004;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC3_DEGASS;
  END_RESOURCE
END_CONFIGURATION
