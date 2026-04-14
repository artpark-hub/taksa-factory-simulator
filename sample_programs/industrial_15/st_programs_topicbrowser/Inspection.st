PROGRAM PLC11_INSPECTION

VAR
    inspection_rate : REAL := 60.0;

    defect_detected : BOOL := FALSE;
    defect_type : INT := 0;

    camera_fault : BOOL := FALSE;

    system_energy : REAL := 20.0;

    inspection_delay : REAL := 0.0;

    camera_health : REAL := 100.0;

    rand : REAL;
    tick : DINT;
END_VAR

VAR_EXTERNAL
    reg_inspection_rate_x10 : UINT;
    reg_defect_detected : UINT;
    reg_defect_type : UINT;
    reg_camera_fault : UINT;
    reg_system_energy_x10 : UINT;
    reg_inspection_delay_x10 : UINT;
    reg_camera_health_x10 : UINT;
END_VAR

rand := DINT_TO_REAL((tick * 43) MOD 100) / 100.0;
tick := tick + 1;

IF rand < 0.02 THEN
    defect_detected := TRUE;
    defect_type := 1;
END_IF;

IF rand < 0.005 THEN
    camera_fault := TRUE;
END_IF;

camera_health := camera_health - 0.0002;

(* Export live values to Modbus holding registers %MW0.. *)
reg_inspection_rate_x10 := REAL_TO_UINT(inspection_rate * 10.0);
IF defect_detected THEN
    reg_defect_detected := 1;
ELSE
    reg_defect_detected := 0;
END_IF;
IF defect_type < 0 THEN
    reg_defect_type := 0;
ELSE
    reg_defect_type := INT_TO_UINT(defect_type);
END_IF;
IF camera_fault THEN
    reg_camera_fault := 1;
ELSE
    reg_camera_fault := 0;
END_IF;
reg_system_energy_x10 := REAL_TO_UINT(system_energy * 10.0);
reg_inspection_delay_x10 := REAL_TO_UINT(inspection_delay * 10.0);
reg_camera_health_x10 := REAL_TO_UINT(camera_health * 10.0);

END_PROGRAM

CONFIGURATION Config0
  RESOURCE Res0 ON PLC
    VAR_GLOBAL
      reg_inspection_rate_x10 AT %MW0 : UINT;
      reg_defect_detected AT %MW1 : UINT;
      reg_defect_type AT %MW2 : UINT;
      reg_camera_fault AT %MW3 : UINT;
      reg_system_energy_x10 AT %MW4 : UINT;
      reg_inspection_delay_x10 AT %MW5 : UINT;
      reg_camera_health_x10 AT %MW6 : UINT;
    END_VAR


    TASK Main(INTERVAL := T#20ms, PRIORITY := 0);
    PROGRAM Inst0 WITH Main : PLC11_INSPECTION;
  END_RESOURCE
END_CONFIGURATION
