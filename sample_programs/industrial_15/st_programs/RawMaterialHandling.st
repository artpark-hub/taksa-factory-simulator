PROGRAM PLC1_RAW_MATERIAL

VAR
    // PQSCDM
    material_feed_rate : REAL := 50.0;
    material_available : BOOL := TRUE;

    material_composition_ok : BOOL := TRUE;

    overload_alarm : BOOL := FALSE;

    energy_usage_conveyor : REAL := 5.0;

    feeder_idle_time : REAL := 0.0;

    motor_health : REAL := 100.0;

    // internal
    rand : REAL := 0.5;
    tick : DINT := 0;
END_VAR

rand := REAL((tick * 13) MOD 100) / 100.0;
tick := tick + 1;

// simulate feed variation
material_feed_rate := 45.0 + (rand * 10.0);

// occasional overload
IF rand < 0.01 THEN
    overload_alarm := TRUE;
ELSE
    overload_alarm := FALSE;
END_IF;

// idle time
IF NOT material_available THEN
    feeder_idle_time := feeder_idle_time + 0.1;
END_IF;

// degradation
motor_health := motor_health - 0.0005;

energy_usage_conveyor := material_feed_rate * 0.1;

END_PROGRAM
