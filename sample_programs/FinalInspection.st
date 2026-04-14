PROGRAM PLC13_FINAL_INSPECTION

VAR
    inspection_cycle : REAL := 30.0;

    crack_detected : BOOL := FALSE;
    pass_fail : BOOL := TRUE;

    radiation_alarm : BOOL := FALSE;

    energy_usage : REAL := 50.0;

    reinspection_time : REAL := 0.0;

    sensor_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

VAR_EXTERNAL
    reg_inspection_cycle_x10 : UINT;
    reg_crack_detected : UINT;
    reg_pass_fail : UINT;
    reg_radiation_alarm : UINT;
    reg_energy_usage_x10 : UINT;
    reg_reinspection_time_x10 : UINT;
    reg_sensor_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 53) MOD 100) / 100.0;
tick := tick + 1;

IF rand < 0.01 THEN
    crack_detected := TRUE;
    pass_fail := FALSE;
END_IF;

sensor_health := sensor_health - 0.0002;

(* Export live values to Modbus holding registers %MW0.. *)
reg_inspection_cycle_x10 := REAL_TO_UINT(inspection_cycle * 10.0);
IF crack_detected THEN
    reg_crack_detected := 1;
ELSE
    reg_crack_detected := 0;
END_IF;
IF pass_fail THEN
    reg_pass_fail := 1;
ELSE
    reg_pass_fail := 0;
END_IF;
IF radiation_alarm THEN
    reg_radiation_alarm := 1;
ELSE
    reg_radiation_alarm := 0;
END_IF;
reg_energy_usage_x10 := REAL_TO_UINT(energy_usage * 10.0);
reg_reinspection_time_x10 := REAL_TO_UINT(reinspection_time * 10.0);
reg_sensor_health_x10 := REAL_TO_UINT(sensor_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_inspection_cycle_x10 AT %MW0 : UINT;
      reg_crack_detected AT %MW1 : UINT;
      reg_pass_fail AT %MW2 : UINT;
      reg_radiation_alarm AT %MW3 : UINT;
      reg_energy_usage_x10 AT %MW4 : UINT;
      reg_reinspection_time_x10 AT %MW5 : UINT;
      reg_sensor_health_x10 AT %MW6 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC13_FINAL_INSPECTION;
  END_RESOURCE
END_CONFIGURATION
