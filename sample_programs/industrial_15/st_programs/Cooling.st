PROGRAM PLC5_COOLING

VAR
    cooling_time : REAL := 120.0;

    cooling_uniformity : REAL := 0.95;

    temp_alarm : BOOL := FALSE;

    water_usage : REAL := 50.0;

    blockage_time : REAL := 0.0;

    pump_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := REAL((tick * 29) MOD 100) / 100.0;
tick := tick + 1;

cooling_time := 100.0 + (rand * 40.0);
cooling_uniformity := 0.9 + (rand * 0.1);

IF rand < 0.01 THEN
    temp_alarm := TRUE;
END_IF;

water_usage := 40.0 + (rand * 20.0);

pump_health := pump_health - 0.0003;

END_PROGRAM
