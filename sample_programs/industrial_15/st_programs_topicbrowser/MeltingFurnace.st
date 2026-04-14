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

VAR_EXTERNAL
    reg_melt_rate_x10 : UINT;
    reg_tap_time_x10 : UINT;
    reg_metal_temperature_x10 : UINT;
    reg_composition_x1000 : UINT;
    reg_overheat_alarm : UINT;
    reg_energy_consumption_x10 : UINT;
    reg_furnace_downtime_x10 : UINT;
    reg_refractory_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 17) MOD 100) / 100.0;
tick := tick + 1;

metal_temperature := 680.0 + (rand * 50.0);

IF metal_temperature > 720.0 THEN
    overheat_alarm := TRUE;
    furnace_downtime := furnace_downtime + 0.1;
ELSE
    overheat_alarm := FALSE;
END_IF;

melt_rate := 90.0 + (rand * 20.0);
energy_consumption := melt_rate * 4.0;

refractory_health := refractory_health - 0.0003;

tap_time := tap_time + 0.1;

(* Export live values to Modbus holding registers %MW0.. *)
reg_melt_rate_x10 := REAL_TO_UINT(melt_rate * 10.0);
reg_tap_time_x10 := REAL_TO_UINT(tap_time * 10.0);
reg_metal_temperature_x10 := REAL_TO_UINT(metal_temperature * 10.0);
reg_composition_x1000 := REAL_TO_UINT(composition * 1000.0);
IF overheat_alarm THEN
    reg_overheat_alarm := 1;
ELSE
    reg_overheat_alarm := 0;
END_IF;
reg_energy_consumption_x10 := REAL_TO_UINT(energy_consumption * 10.0);
reg_furnace_downtime_x10 := REAL_TO_UINT(furnace_downtime * 10.0);
reg_refractory_health_x10 := REAL_TO_UINT(refractory_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_melt_rate_x10 AT %MW0 : UINT;
      reg_tap_time_x10 AT %MW1 : UINT;
      reg_metal_temperature_x10 AT %MW2 : UINT;
      reg_composition_x1000 AT %MW3 : UINT;
      reg_overheat_alarm AT %MW4 : UINT;
      reg_energy_consumption_x10 AT %MW5 : UINT;
      reg_furnace_downtime_x10 AT %MW6 : UINT;
      reg_refractory_health_x10 AT %MW7 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC2_FURNACE;
  END_RESOURCE
END_CONFIGURATION
