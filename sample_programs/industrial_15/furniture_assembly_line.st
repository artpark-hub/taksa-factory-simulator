PROGRAM furniture_assembly_line
  VAR
    machine_status : UINT := 2;
    planned_time_s : DINT := 0;
    runtime_time_s : DINT := 0;
    downtime_time_s : DINT := 0;
    total_count : DINT := 0;
    good_count : DINT := 0;
    reject_count : DINT := 0;

    availability_pct : REAL := 0.0;
    performance_pct : REAL := 0.0;
    quality_pct : REAL := 0.0;

    part_present : BOOL := FALSE;
    cycle_time_s : REAL := 0.0;
    door_open : BOOL := TRUE;

    sim_state : UINT := 0;
    state_sec : UINT := 0;
    scan_ticks : UINT := 0;
    part_timer_s : REAL := 0.0;
    reject_counter : UINT := 0;

    startup_limit : UINT := 6;
    run_limit : UINT := 155;
    stop_limit : UINT := 11;
    run_cycle_const : REAL := 5.10;
    stop_cycle_const : REAL := 4.30;
    ideal_cycle_const : REAL := 4.50;
    reject_every_n_parts : UINT := 50;
  END_VAR

  VAR_EXTERNAL
    rd_machine_status : UINT;
    rd_planned_time_s : UINT;
    rd_runtime_time_s : UINT;
    rd_downtime_time_s : UINT;
    rd_total_count : UINT;
    rd_good_count : UINT;
    rd_reject_count : UINT;
    rd_availability_x100 : UINT;
    rd_performance_x100 : UINT;
    rd_quality_x100 : UINT;
    rd_part_present : UINT;
    rd_cycle_time_x100 : UINT;
    rd_door_open : UINT;

    wr_startup_limit : UINT;
    wr_run_limit : UINT;
    wr_stop_limit : UINT;
    wr_run_cycle_const_x100 : UINT;
    wr_stop_cycle_const_x100 : UINT;
    wr_ideal_cycle_const_x100 : UINT;
    wr_reject_every_n_parts : UINT;
  END_VAR

  IF wr_startup_limit > 0 THEN
      startup_limit := wr_startup_limit;
  END_IF;

  IF wr_run_limit > 0 THEN
      run_limit := wr_run_limit;
  END_IF;

  IF wr_stop_limit > 0 THEN
      stop_limit := wr_stop_limit;
  END_IF;

  IF wr_run_cycle_const_x100 > 0 THEN
      run_cycle_const := UINT_TO_REAL(wr_run_cycle_const_x100) / 100.0;
  END_IF;

  IF wr_stop_cycle_const_x100 > 0 THEN
      stop_cycle_const := UINT_TO_REAL(wr_stop_cycle_const_x100) / 100.0;
  END_IF;

  IF wr_ideal_cycle_const_x100 > 0 THEN
      ideal_cycle_const := UINT_TO_REAL(wr_ideal_cycle_const_x100) / 100.0;
  END_IF;

  IF wr_reject_every_n_parts > 0 THEN
      reject_every_n_parts := wr_reject_every_n_parts;
  END_IF;

  scan_ticks := scan_ticks + 1;

  IF scan_ticks >= 50 THEN
      scan_ticks := 0;
      state_sec := state_sec + 1;
      planned_time_s := planned_time_s + 1;

      CASE sim_state OF
          0:
              machine_status := 2;
              door_open := TRUE;
              part_present := FALSE;
              cycle_time_s := 0.0;
              downtime_time_s := downtime_time_s + 1;

              IF state_sec >= startup_limit THEN
                  sim_state := 1;
                  state_sec := 0;
                  part_timer_s := 0.0;
              END_IF;

          1:
              machine_status := 1;
              door_open := FALSE;
              part_present := TRUE;
              runtime_time_s := runtime_time_s + 1;
              part_timer_s := part_timer_s + 1.0;
              cycle_time_s := part_timer_s;

              IF part_timer_s >= run_cycle_const THEN
                  part_timer_s := part_timer_s - run_cycle_const;
                  total_count := total_count + 1;
                  reject_counter := reject_counter + 1;

                  IF reject_every_n_parts > 0 AND reject_counter >= reject_every_n_parts THEN
                      reject_count := reject_count + 1;
                      reject_counter := 0;
                  ELSE
                      good_count := good_count + 1;
                  END_IF;
              END_IF;

              IF state_sec >= run_limit THEN
                  sim_state := 2;
                  state_sec := 0;
              END_IF;

          2:
              machine_status := 3;
              door_open := TRUE;
              part_present := FALSE;
              cycle_time_s := stop_cycle_const;
              downtime_time_s := downtime_time_s + 1;

              IF state_sec >= stop_limit THEN
                  sim_state := 0;
                  state_sec := 0;
              END_IF;
      END_CASE;
  END_IF;

  IF planned_time_s > 0 THEN
      availability_pct := (DINT_TO_REAL(runtime_time_s) / DINT_TO_REAL(planned_time_s)) * 100.0;
  ELSE
      availability_pct := 0.0;
  END_IF;

  IF runtime_time_s > 0 THEN
      performance_pct := ((DINT_TO_REAL(total_count) * ideal_cycle_const) / DINT_TO_REAL(runtime_time_s)) * 100.0;
      IF performance_pct > 100.0 THEN
          performance_pct := 100.0;
      END_IF;
  ELSE
      performance_pct := 0.0;
  END_IF;

  IF total_count > 0 THEN
      quality_pct := (DINT_TO_REAL(good_count) / DINT_TO_REAL(total_count)) * 100.0;
  ELSE
      quality_pct := 0.0;
  END_IF;

  rd_machine_status := machine_status;

  IF planned_time_s < 0 THEN
      rd_planned_time_s := 0;
  ELSIF planned_time_s > 65535 THEN
      rd_planned_time_s := 65535;
  ELSE
      rd_planned_time_s := DINT_TO_UINT(planned_time_s);
  END_IF;

  IF runtime_time_s < 0 THEN
      rd_runtime_time_s := 0;
  ELSIF runtime_time_s > 65535 THEN
      rd_runtime_time_s := 65535;
  ELSE
      rd_runtime_time_s := DINT_TO_UINT(runtime_time_s);
  END_IF;

  IF downtime_time_s < 0 THEN
      rd_downtime_time_s := 0;
  ELSIF downtime_time_s > 65535 THEN
      rd_downtime_time_s := 65535;
  ELSE
      rd_downtime_time_s := DINT_TO_UINT(downtime_time_s);
  END_IF;

  rd_total_count := DINT_TO_UINT(total_count);
  rd_good_count := DINT_TO_UINT(good_count);
  rd_reject_count := DINT_TO_UINT(reject_count);
  rd_availability_x100 := REAL_TO_UINT(availability_pct * 100.0);
  rd_performance_x100 := REAL_TO_UINT(performance_pct * 100.0);
  rd_quality_x100 := REAL_TO_UINT(quality_pct * 100.0);

  IF part_present THEN
      rd_part_present := 1;
  ELSE
      rd_part_present := 0;
  END_IF;

  rd_cycle_time_x100 := REAL_TO_UINT(cycle_time_s * 100.0);

  IF door_open THEN
      rd_door_open := 1;
  ELSE
      rd_door_open := 0;
  END_IF;
END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      rd_machine_status AT %MW0 : UINT;
      rd_planned_time_s AT %MW1 : UINT;
      rd_runtime_time_s AT %MW2 : UINT;
      rd_downtime_time_s AT %MW3 : UINT;
      rd_total_count AT %MW4 : UINT;
      rd_good_count AT %MW5 : UINT;
      rd_reject_count AT %MW6 : UINT;
      rd_availability_x100 AT %MW7 : UINT;
      rd_performance_x100 AT %MW8 : UINT;
      rd_quality_x100 AT %MW9 : UINT;
      rd_part_present AT %MW10 : UINT;
      rd_cycle_time_x100 AT %MW11 : UINT;
      rd_door_open AT %MW12 : UINT;

      wr_startup_limit AT %MW100 : UINT;
      wr_run_limit AT %MW101 : UINT;
      wr_stop_limit AT %MW102 : UINT;
      wr_run_cycle_const_x100 AT %MW103 : UINT;
      wr_stop_cycle_const_x100 AT %MW104 : UINT;
      wr_ideal_cycle_const_x100 AT %MW105 : UINT;
      wr_reject_every_n_parts AT %MW106 : UINT;
    END_VAR

    TASK task0(INTERVAL := T#20ms,PRIORITY := 1);
    PROGRAM instance0 WITH task0 : furniture_assembly_line;
  END_RESOURCE
END_CONFIGURATION
