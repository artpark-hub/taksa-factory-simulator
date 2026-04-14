PROGRAM PLC9_CNC

VAR
    cycle_time : REAL := 120.0;
    throughput : REAL := 30.0;

    dimension_ok : BOOL := TRUE;
    surface_finish : REAL := 0.95;

    tool_break_alarm : BOOL := FALSE;

    spindle_energy : REAL := 50.0;

    machine_idle : REAL := 0.0;

    spindle_load : REAL := 70.0;
    tool_life : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

VAR_EXTERNAL
    reg_cycle_time_x10 : UINT;
    reg_throughput_x10 : UINT;
    reg_dimension_ok : UINT;
    reg_surface_finish_x1000 : UINT;
    reg_tool_break_alarm : UINT;
    reg_spindle_energy_x10 : UINT;
    reg_machine_idle_x10 : UINT;
    reg_spindle_load_x10 : UINT;
    reg_tool_life_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 41) MOD 100) / 100.0;
tick := tick + 1;

cycle_time := 100.0 + (rand * 40.0);
throughput := 3600.0 / cycle_time;

spindle_load := 60.0 + (rand * 30.0);

IF rand < 0.01 THEN
    tool_break_alarm := TRUE;
    dimension_ok := FALSE;
END_IF;

tool_life := tool_life - 0.001;

spindle_energy := spindle_load * 0.8;

(* Export live values to Modbus holding registers %MW0.. *)
reg_cycle_time_x10 := REAL_TO_UINT(cycle_time * 10.0);
reg_throughput_x10 := REAL_TO_UINT(throughput * 10.0);
IF dimension_ok THEN
    reg_dimension_ok := 1;
ELSE
    reg_dimension_ok := 0;
END_IF;
reg_surface_finish_x1000 := REAL_TO_UINT(surface_finish * 1000.0);
IF tool_break_alarm THEN
    reg_tool_break_alarm := 1;
ELSE
    reg_tool_break_alarm := 0;
END_IF;
reg_spindle_energy_x10 := REAL_TO_UINT(spindle_energy * 10.0);
reg_machine_idle_x10 := REAL_TO_UINT(machine_idle * 10.0);
reg_spindle_load_x10 := REAL_TO_UINT(spindle_load * 10.0);
reg_tool_life_x10 := REAL_TO_UINT(tool_life * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_cycle_time_x10 AT %MW0 : UINT;
      reg_throughput_x10 AT %MW1 : UINT;
      reg_dimension_ok AT %MW2 : UINT;
      reg_surface_finish_x1000 AT %MW3 : UINT;
      reg_tool_break_alarm AT %MW4 : UINT;
      reg_spindle_energy_x10 AT %MW5 : UINT;
      reg_machine_idle_x10 AT %MW6 : UINT;
      reg_spindle_load_x10 AT %MW7 : UINT;
      reg_tool_life_x10 AT %MW8 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC9_CNC;
  END_RESOURCE
END_CONFIGURATION
