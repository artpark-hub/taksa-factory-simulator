PROGRAM PLC15_UTILS

VAR
    supply_rate : REAL := 100.0;

    pressure_stability : REAL := 0.95;

    power_fault : BOOL := FALSE;

    total_energy : REAL := 1000.0;

    outage_time : REAL := 0.0;

    compressor_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

VAR_EXTERNAL
    reg_supply_rate_x10 : UINT;
    reg_pressure_stability_x1000 : UINT;
    reg_power_fault : UINT;
    reg_total_energy_x10 : UINT;
    reg_outage_time_x10 : UINT;
    reg_compressor_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 61) MOD 100) / 100.0;
tick := tick + 1;

pressure_stability := 0.9 + (rand * 0.1);

IF rand < 0.005 THEN
    power_fault := TRUE;
    outage_time := outage_time + 0.1;
END_IF;

total_energy := total_energy + (rand * 10.0);

compressor_health := compressor_health - 0.0004;

(* Export live values to Modbus holding registers %MW0.. *)
reg_supply_rate_x10 := REAL_TO_UINT(supply_rate * 10.0);
reg_pressure_stability_x1000 := REAL_TO_UINT(pressure_stability * 1000.0);
IF power_fault THEN
    reg_power_fault := 1;
ELSE
    reg_power_fault := 0;
END_IF;
reg_total_energy_x10 := REAL_TO_UINT(total_energy * 10.0);
reg_outage_time_x10 := REAL_TO_UINT(outage_time * 10.0);
reg_compressor_health_x10 := REAL_TO_UINT(compressor_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_supply_rate_x10 AT %MW0 : UINT;
      reg_pressure_stability_x1000 AT %MW1 : UINT;
      reg_power_fault AT %MW2 : UINT;
      reg_total_energy_x10 AT %MW3 : UINT;
      reg_outage_time_x10 AT %MW4 : UINT;
      reg_compressor_health_x10 AT %MW5 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC15_UTILS;
  END_RESOURCE
END_CONFIGURATION
