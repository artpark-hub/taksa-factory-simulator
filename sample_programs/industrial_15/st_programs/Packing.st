PROGRAM PLC14_PACKING

VAR
    packing_rate : REAL := 100.0;

    packing_ok : BOOL := TRUE;

    jam_alarm : BOOL := FALSE;

    material_usage : REAL := 20.0;

    downtime : REAL := 0.0;

    robot_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := REAL((tick * 59) MOD 100) / 100.0;
tick := tick + 1;

IF rand < 0.01 THEN
    jam_alarm := TRUE;
END_IF;

robot_health := robot_health - 0.0003;

END_PROGRAM
