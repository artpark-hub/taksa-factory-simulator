PROGRAM PLC11_INSPECTION

VAR
    inspection_rate : REAL := 60.0;

    defect_detected : BOOL := FALSE;
    defect_type : INT := 0;

    camera_fault : BOOL := FALSE;

    system_energy : REAL := 20.0;

    inspection_delay : REAL := 0.0;

    camera_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := DINT_TO_REAL((tick * 43) MOD 100) / 100.0;
tick := tick + 1;

IF rand < 0.02 THEN
    defect_detected := TRUE;
    defect_type := 1;
END_IF;

IF rand < 0.005 THEN
    camera_fault := TRUE;
END_IF;

camera_health := camera_health - 0.0002;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC11_INSPECTION;
  END_RESOURCE
END_CONFIGURATION
