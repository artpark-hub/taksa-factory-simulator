PROGRAM PLC7_SHOTBLAST

VAR
    cycle_time : REAL := 60.0;

    surface_cleanliness : REAL := 0.95;

    vibration_alarm : BOOL := FALSE;

    media_usage : REAL := 5.0;

    jam_time : REAL := 0.0;

    turbine_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

VAR_EXTERNAL
    reg_cycle_time_x10 : UINT;
    reg_surface_cleanliness_x1000 : UINT;
    reg_vibration_alarm : UINT;
    reg_media_usage_x10 : UINT;
    reg_jam_time_x10 : UINT;
    reg_turbine_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 37) MOD 100) / 100.0;
tick := tick + 1;

surface_cleanliness := 0.9 + (rand * 0.1);

IF rand < 0.01 THEN
    vibration_alarm := TRUE;
END_IF;

media_usage := 4.0 + (rand * 2.0);

turbine_health := turbine_health - 0.0003;

(* Export live values to Modbus holding registers %MW0.. *)
reg_cycle_time_x10 := REAL_TO_UINT(cycle_time * 10.0);
reg_surface_cleanliness_x1000 := REAL_TO_UINT(surface_cleanliness * 1000.0);
IF vibration_alarm THEN
    reg_vibration_alarm := 1;
ELSE
    reg_vibration_alarm := 0;
END_IF;
reg_media_usage_x10 := REAL_TO_UINT(media_usage * 10.0);
reg_jam_time_x10 := REAL_TO_UINT(jam_time * 10.0);
reg_turbine_health_x10 := REAL_TO_UINT(turbine_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_cycle_time_x10 AT %MW0 : UINT;
      reg_surface_cleanliness_x1000 AT %MW1 : UINT;
      reg_vibration_alarm AT %MW2 : UINT;
      reg_media_usage_x10 AT %MW3 : UINT;
      reg_jam_time_x10 AT %MW4 : UINT;
      reg_turbine_health_x10 AT %MW5 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC7_SHOTBLAST;
  END_RESOURCE
END_CONFIGURATION
