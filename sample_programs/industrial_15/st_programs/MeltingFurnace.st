PROGRAM PLC2_FURNACE

VAR
    melt_rate : REAL := 100.0;
    tap_time  : REAL := 0.0;

    metal_temperature : REAL := 700.0;
    composition : REAL := 0.95;

    overheat_alarm : BOOL := FALSE;

    energy_consumption : REAL := 500.0;

    furnace_downtime : REAL := 0.0;

    refractory_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

rand := REAL((tick * 17) MOD 100) / 100.0;
tick := tick + 1;

// temperature control
metal_temperature := 680.0 + (rand * 50.0);

// overheat
IF metal_temperature > 720.0 THEN
    overheat_alarm := TRUE;
    furnace_downtime := furnace_downtime + 0.1;
ELSE
    overheat_alarm := FALSE;
END_IF;

melt_rate := 90.0 + (rand * 20.0);
energy_consumption := melt_rate * 4.0;

// degradation
refractory_health := refractory_health - 0.0003;

tap_time := tap_time + 0.1;

END_PROGRAM
