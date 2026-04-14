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

VAR_EXTERNAL
    reg_material_feed_rate_x10 : UINT;
    reg_material_available : UINT;
    reg_material_composition_ok : UINT;
    reg_overload_alarm : UINT;
    reg_energy_usage_conveyor_x10 : UINT;
    reg_feeder_idle_time_x10 : UINT;
    reg_motor_health_x10 : UINT;
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

(* Export live values to Modbus holding registers %MW0.. *)
reg_material_feed_rate_x10 := REAL_TO_UINT(material_feed_rate * 10.0);
IF material_available THEN
    reg_material_available := 1;
ELSE
    reg_material_available := 0;
END_IF;
IF material_composition_ok THEN
    reg_material_composition_ok := 1;
ELSE
    reg_material_composition_ok := 0;
END_IF;
IF overload_alarm THEN
    reg_overload_alarm := 1;
ELSE
    reg_overload_alarm := 0;
END_IF;
reg_energy_usage_conveyor_x10 := REAL_TO_UINT(energy_usage_conveyor * 10.0);
reg_feeder_idle_time_x10 := REAL_TO_UINT(feeder_idle_time * 10.0);
reg_motor_health_x10 := REAL_TO_UINT(motor_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_material_feed_rate_x10 AT %MW0 : UINT;
      reg_material_available AT %MW1 : UINT;
      reg_material_composition_ok AT %MW2 : UINT;
      reg_overload_alarm AT %MW3 : UINT;
      reg_energy_usage_conveyor_x10 AT %MW4 : UINT;
      reg_feeder_idle_time_x10 AT %MW5 : UINT;
      reg_motor_health_x10 AT %MW6 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC1_RAW_MATERIAL;
  END_RESOURCE
END_CONFIGURATION
