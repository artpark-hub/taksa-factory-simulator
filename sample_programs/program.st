PROGRAM main
VAR
    start_button AT %IX0.0 : BOOL;
    motor        AT %QX0.0 : BOOL;
    counter      AT %MW0   : INT := 0;
END_VAR

(* Logic *)
IF start_button THEN
    motor := TRUE;
    counter := counter + 1;
ELSE
    motor := FALSE;
END_IF;

END_PROGRAM
