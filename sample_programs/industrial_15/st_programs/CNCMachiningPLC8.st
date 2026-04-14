PROGRAM PLC8_CNC

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

rand := REAL((tick * 41) MOD 100) / 100.0;
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

END_PROGRAM
