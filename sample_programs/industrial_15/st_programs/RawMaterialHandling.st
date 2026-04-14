PROGRAM PLC1_RAW_MATERIAL

VAR

    material_feed_rate : REAL := 50.0;
    material_available : BOOL := TRUE;

    material_composition_ok : BOOL := TRUE;

    overload_alarm : BOOL := FALSE;

    energy_usage_conveyor : REAL := 5.0;

    feeder_idle_time : REAL := 0.0;

    motor_health : REAL := 100.0;


    rand : REAL := 0.5;
    tick : DINT := 0;
END_VAR

rand := DINT_TO_REAL((tick * 13) MOD 100) / 100.0;
tick := tick + 1;


material_feed_rate := 45.0 + (rand * 10.0);


IF rand < 0.01 THEN
    overload_alarm := TRUE;
ELSE
    overload_alarm := FALSE;
END_IF;


IF NOT material_available THEN
    feeder_idle_time := feeder_idle_time + 0.1;
END_IF;


motor_health := motor_health - 0.0005;

energy_usage_conveyor := material_feed_rate * 0.1;

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC1_RAW_MATERIAL;
  END_RESOURCE
END_CONFIGURATION
