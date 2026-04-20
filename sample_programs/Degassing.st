PROGRAM PLC3_DEGASS

VAR
    treatment_cycle_time : REAL := 60.0;

    gas_content_level : REAL := 0.02;

    gas_leak_alarm : BOOL := FALSE;

    gas_consumption : REAL := 10.0;

    idle_time : REAL := 0.0;

    rotor_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

VAR_EXTERNAL
    reg_treatment_cycle_time_x10 : UINT;
    reg_gas_content_level_x10000 : UINT;
    reg_gas_leak_alarm : UINT;
    reg_gas_consumption_x10 : UINT;
    reg_idle_time_x10 : UINT;
    reg_rotor_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 19) MOD 100) / 100.0;
tick := tick + 1;

gas_content_level := 0.01 + (rand * 0.02);

IF rand < 0.005 THEN
    gas_leak_alarm := TRUE;
ELSE
    gas_leak_alarm := FALSE;
END_IF;

gas_consumption := 8.0 + (rand * 4.0);

rotor_health := rotor_health - 0.0004;

(* Export live values to Modbus holding registers %MW0.. *)
reg_treatment_cycle_time_x10 := REAL_TO_UINT(treatment_cycle_time * 10.0);
reg_gas_content_level_x10000 := REAL_TO_UINT(gas_content_level * 10000.0);
IF gas_leak_alarm THEN
    reg_gas_leak_alarm := 1;
ELSE
    reg_gas_leak_alarm := 0;
END_IF;
reg_gas_consumption_x10 := REAL_TO_UINT(gas_consumption * 10.0);
reg_idle_time_x10 := REAL_TO_UINT(idle_time * 10.0);
reg_rotor_health_x10 := REAL_TO_UINT(rotor_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_treatment_cycle_time_x10 AT %MW0 : UINT;
      reg_gas_content_level_x10000 AT %MW1 : UINT;
      reg_gas_leak_alarm AT %MW2 : UINT;
      reg_gas_consumption_x10 AT %MW3 : UINT;
      reg_idle_time_x10 AT %MW4 : UINT;
      reg_rotor_health_x10 AT %MW5 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC3_DEGASS;
  END_RESOURCE
END_CONFIGURATION
