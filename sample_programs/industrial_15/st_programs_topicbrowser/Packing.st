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

VAR_EXTERNAL
    reg_packing_rate_x10 : UINT;
    reg_packing_ok : UINT;
    reg_jam_alarm : UINT;
    reg_material_usage_x10 : UINT;
    reg_downtime_x10 : UINT;
    reg_robot_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 59) MOD 100) / 100.0;
tick := tick + 1;

IF rand < 0.01 THEN
    jam_alarm := TRUE;
END_IF;

robot_health := robot_health - 0.0003;

(* Export live values to Modbus holding registers %MW0.. *)
reg_packing_rate_x10 := REAL_TO_UINT(packing_rate * 10.0);
IF packing_ok THEN
    reg_packing_ok := 1;
ELSE
    reg_packing_ok := 0;
END_IF;
IF jam_alarm THEN
    reg_jam_alarm := 1;
ELSE
    reg_jam_alarm := 0;
END_IF;
reg_material_usage_x10 := REAL_TO_UINT(material_usage * 10.0);
reg_downtime_x10 := REAL_TO_UINT(downtime * 10.0);
reg_robot_health_x10 := REAL_TO_UINT(robot_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_packing_rate_x10 AT %MW0 : UINT;
      reg_packing_ok AT %MW1 : UINT;
      reg_jam_alarm AT %MW2 : UINT;
      reg_material_usage_x10 AT %MW3 : UINT;
      reg_downtime_x10 AT %MW4 : UINT;
      reg_robot_health_x10 AT %MW5 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC14_PACKING;
  END_RESOURCE
END_CONFIGURATION
