PROGRAM PLC15_UTILS

VAR
    supply_rate : REAL := 100.0;

    pressure_stability : REAL := 0.95;

    power_fault : BOOL := FALSE;

    total_energy : REAL := 1000.0;

    outage_time : REAL := 0.0;

    compressor_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := DINT_TO_REAL((tick * 61) MOD 100) / 100.0;
tick := tick + 1;

pressure_stability := 0.9 + (rand * 0.1);

IF rand < 0.005 THEN
    power_fault := TRUE;
    outage_time := outage_time + 0.1;
END_IF;

total_energy := total_energy + (rand * 10.0);

compressor_health := compressor_health - 0.0004;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC15_UTILS;
  END_RESOURCE
END_CONFIGURATION
