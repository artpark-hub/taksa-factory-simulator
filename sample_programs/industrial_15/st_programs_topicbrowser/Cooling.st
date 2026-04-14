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

VAR_EXTERNAL
    reg_cooling_time_x10 : UINT;
    reg_cooling_uniformity_x1000 : UINT;
    reg_temp_alarm : UINT;
    reg_water_usage_x10 : UINT;
    reg_blockage_time_x10 : UINT;
    reg_pump_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 29) MOD 100) / 100.0;
tick := tick + 1;

cooling_time := 100.0 + (rand * 40.0);
cooling_uniformity := 0.9 + (rand * 0.1);

IF rand < 0.01 THEN
    temp_alarm := TRUE;
END_IF;

water_usage := 40.0 + (rand * 20.0);

pump_health := pump_health - 0.0003;

(* Export live values to Modbus holding registers %MW0.. *)
reg_cooling_time_x10 := REAL_TO_UINT(cooling_time * 10.0);
reg_cooling_uniformity_x1000 := REAL_TO_UINT(cooling_uniformity * 1000.0);
IF temp_alarm THEN
    reg_temp_alarm := 1;
ELSE
    reg_temp_alarm := 0;
END_IF;
reg_water_usage_x10 := REAL_TO_UINT(water_usage * 10.0);
reg_blockage_time_x10 := REAL_TO_UINT(blockage_time * 10.0);
reg_pump_health_x10 := REAL_TO_UINT(pump_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_cooling_time_x10 AT %MW0 : UINT;
      reg_cooling_uniformity_x1000 AT %MW1 : UINT;
      reg_temp_alarm AT %MW2 : UINT;
      reg_water_usage_x10 AT %MW3 : UINT;
      reg_blockage_time_x10 AT %MW4 : UINT;
      reg_pump_health_x10 AT %MW5 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC5_COOLING;
  END_RESOURCE
END_CONFIGURATION
