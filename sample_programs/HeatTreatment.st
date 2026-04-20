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

VAR_EXTERNAL
    reg_batch_cycle_time_s : UINT;
    reg_hardness_x10 : UINT;
    reg_temperature_profile_x10 : UINT;
    reg_furnace_alarm : UINT;
    reg_fuel_consumption_x10 : UINT;
    reg_downtime_x10 : UINT;
    reg_heater_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 31) MOD 100) / 100.0;
tick := tick + 1;

temperature_profile := 480.0 + (rand * 40.0);

IF rand < 0.01 THEN
    furnace_alarm := TRUE;
END_IF;

fuel_consumption := 250.0 + (rand * 100.0);

heater_health := heater_health - 0.0004;

(* Export live values to Modbus holding registers %MW0.. *)
reg_batch_cycle_time_s := REAL_TO_UINT(batch_cycle_time);
reg_hardness_x10 := REAL_TO_UINT(hardness * 10.0);
reg_temperature_profile_x10 := REAL_TO_UINT(temperature_profile * 10.0);
IF furnace_alarm THEN
    reg_furnace_alarm := 1;
ELSE
    reg_furnace_alarm := 0;
END_IF;
reg_fuel_consumption_x10 := REAL_TO_UINT(fuel_consumption * 10.0);
reg_downtime_x10 := REAL_TO_UINT(downtime * 10.0);
reg_heater_health_x10 := REAL_TO_UINT(heater_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_batch_cycle_time_s AT %MW0 : UINT;
      reg_hardness_x10 AT %MW1 : UINT;
      reg_temperature_profile_x10 AT %MW2 : UINT;
      reg_furnace_alarm AT %MW3 : UINT;
      reg_fuel_consumption_x10 AT %MW4 : UINT;
      reg_downtime_x10 AT %MW5 : UINT;
      reg_heater_health_x10 AT %MW6 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC6_HEATTREAT;
  END_RESOURCE
END_CONFIGURATION
