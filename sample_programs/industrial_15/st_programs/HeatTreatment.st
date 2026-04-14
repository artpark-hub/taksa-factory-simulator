PROGRAM PLC6_HEATTREAT

VAR
    batch_cycle_time : REAL := 3600.0;

    hardness : REAL := 80.0;
    temperature_profile : REAL := 500.0;

    furnace_alarm : BOOL := FALSE;

    fuel_consumption : REAL := 300.0;

    downtime : REAL := 0.0;

    heater_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := REAL((tick * 31) MOD 100) / 100.0;
tick := tick + 1;

temperature_profile := 480.0 + (rand * 40.0);

IF rand < 0.01 THEN
    furnace_alarm := TRUE;
END_IF;

fuel_consumption := 250.0 + (rand * 100.0);

heater_health := heater_health - 0.0004;

END_PROGRAM
