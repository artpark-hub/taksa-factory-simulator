PROGRAM PLC13_FINAL_INSPECTION

VAR
    inspection_cycle : REAL := 30.0;

    crack_detected : BOOL := FALSE;
    pass_fail : BOOL := TRUE;

    radiation_alarm : BOOL := FALSE;

    energy_usage : REAL := 50.0;

    reinspection_time : REAL := 0.0;

    sensor_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := REAL((tick * 53) MOD 100) / 100.0;
tick := tick + 1;

IF rand < 0.01 THEN
    crack_detected := TRUE;
    pass_fail := FALSE;
END_IF;

sensor_health := sensor_health - 0.0002;

END_PROGRAM
