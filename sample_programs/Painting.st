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

VAR_EXTERNAL
    reg_coating_rate_x10 : UINT;
    reg_thickness_x10 : UINT;
    reg_finish_quality_x1000 : UINT;
    reg_oven_alarm : UINT;
    reg_powder_usage_x10 : UINT;
    reg_energy_x10 : UINT;
    reg_line_stop_time_x10 : UINT;
    reg_nozzle_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 47) MOD 100) / 100.0;
tick := tick + 1;

thickness := 45.0 + (rand * 10.0);

IF rand < 0.01 THEN
    oven_alarm := TRUE;
END_IF;

nozzle_health := nozzle_health - 0.0003;

(* Export live values to Modbus holding registers %MW0.. *)
reg_coating_rate_x10 := REAL_TO_UINT(coating_rate * 10.0);
reg_thickness_x10 := REAL_TO_UINT(thickness * 10.0);
reg_finish_quality_x1000 := REAL_TO_UINT(finish_quality * 1000.0);
IF oven_alarm THEN
    reg_oven_alarm := 1;
ELSE
    reg_oven_alarm := 0;
END_IF;
reg_powder_usage_x10 := REAL_TO_UINT(powder_usage * 10.0);
reg_energy_x10 := REAL_TO_UINT(energy * 10.0);
reg_line_stop_time_x10 := REAL_TO_UINT(line_stop_time * 10.0);
reg_nozzle_health_x10 := REAL_TO_UINT(nozzle_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_coating_rate_x10 AT %MW0 : UINT;
      reg_thickness_x10 AT %MW1 : UINT;
      reg_finish_quality_x1000 AT %MW2 : UINT;
      reg_oven_alarm AT %MW3 : UINT;
      reg_powder_usage_x10 AT %MW4 : UINT;
      reg_energy_x10 AT %MW5 : UINT;
      reg_line_stop_time_x10 AT %MW6 : UINT;
      reg_nozzle_health_x10 AT %MW7 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC12_PAINT;
  END_RESOURCE
END_CONFIGURATION
