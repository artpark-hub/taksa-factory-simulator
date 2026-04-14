PROGRAM PLC12_PAINT

VAR
    coating_rate : REAL := 40.0;

    thickness : REAL := 50.0;
    finish_quality : REAL := 0.95;

    oven_alarm : BOOL := FALSE;

    powder_usage : REAL := 10.0;
    energy : REAL := 200.0;

    line_stop_time : REAL := 0.0;

    nozzle_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := REAL((tick * 47) MOD 100) / 100.0;
tick := tick + 1;

thickness := 45.0 + (rand * 10.0);

IF rand < 0.01 THEN
    oven_alarm := TRUE;
END_IF;

nozzle_health := nozzle_health - 0.0003;

END_PROGRAM
