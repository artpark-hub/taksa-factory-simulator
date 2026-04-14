# Sample ST Programs (15 PLCs)

These 15 Structured Text programs are in:
`sample_programs/industrial_15/st_programs/`

RW tags below are the primary simulation control knobs.

| PLC | File | Description | RO Tags | RW Tags |
|---|---|---|---|---|
| PLC-1 | `RawMaterialHandling.st` | Raw material feed and availability | `material_feed_rate`, `material_available`, `material_composition_ok`, `overload_alarm`, `energy_usage_conveyor`, `feeder_idle_time`, `motor_health` | `material_available`, `material_composition_ok` |
| PLC-2 | `MeltingFurnace.st` | Furnace melt and alloy behavior | `melt_rate`, `tap_time`, `metal_temperature`, `composition`, `overheat_alarm`, `energy_consumption`, `furnace_downtime`, `refractory_health` | `metal_temperature`, `composition` |
| PLC-3 | `Degassing.st` | Degassing quality and gas behavior | `treatment_cycle_time`, `gas_content_level`, `gas_leak_alarm`, `gas_consumption`, `idle_time`, `rotor_health` | `gas_content_level` |
| PLC-4 | `Press.st` | Casting/forging press throughput + defects | `cycle_time`, `parts_per_hour`, `porosity_flag`, `fill_quality`, `pressure_alarm`, `hydraulic_energy`, `press_idle_time`, `press_load`, `die_health` | `press_load`, `fill_quality` |
| PLC-5 | `Cooling.st` | Cooling stability and flow | `cooling_time`, `cooling_uniformity`, `temp_alarm`, `water_usage`, `blockage_time`, `pump_health` | `cooling_uniformity` |
| PLC-6 | `HeatTreatment.st` | Heat treatment profile and hardness impact | `batch_cycle_time`, `hardness`, `temperature_profile`, `furnace_alarm`, `fuel_consumption`, `downtime`, `heater_health` | `temperature_profile` |
| PLC-7 | `ShotBlasting.st` | Surface cleaning and blasting health | `cycle_time`, `surface_cleanliness`, `vibration_alarm`, `media_usage`, `jam_time`, `turbine_health` | `surface_cleanliness` |
| PLC-8 | `CNCMachiningPLC8.st` | CNC machining line (same tag model for 8/9/10) | `cycle_time`, `throughput`, `dimension_ok`, `surface_finish`, `tool_break_alarm`, `spindle_energy`, `machine_idle`, `spindle_load`, `tool_life` | `spindle_load`, `tool_life` |
| PLC-9 | `CNCMachiningPLC9.st` | CNC machining line (same tag model for 8/9/10) | `cycle_time`, `throughput`, `dimension_ok`, `surface_finish`, `tool_break_alarm`, `spindle_energy`, `machine_idle`, `spindle_load`, `tool_life` | `spindle_load`, `tool_life` |
| PLC-10 | `CNCMachiningPLC10.st` | CNC machining line (same tag model for 8/9/10) | `cycle_time`, `throughput`, `dimension_ok`, `surface_finish`, `tool_break_alarm`, `spindle_energy`, `machine_idle`, `spindle_load`, `tool_life` | `spindle_load`, `tool_life` |
| PLC-11 | `Inspection.st` | Inline defect inspection | `inspection_rate`, `defect_detected`, `defect_type`, `camera_fault`, `system_energy`, `inspection_delay`, `camera_health` | `defect_detected`, `camera_fault` |
| PLC-12 | `Painting.st` | Surface finishing/paint quality | `coating_rate`, `thickness`, `finish_quality`, `oven_alarm`, `powder_usage`, `energy`, `line_stop_time`, `nozzle_health` | `thickness`, `finish_quality` |
| PLC-13 | `FinalInspection.st` | Final quality gate | `inspection_cycle`, `crack_detected`, `pass_fail`, `radiation_alarm`, `energy_usage`, `reinspection_time`, `sensor_health` | `crack_detected`, `pass_fail` |
| PLC-14 | `Packing.st` | Packing and dispatch readiness | `packing_rate`, `packing_ok`, `jam_alarm`, `material_usage`, `downtime`, `robot_health` | `packing_ok` |
| PLC-15 | `Utilities.st` | Plant utilities and global stability | `supply_rate`, `pressure_stability`, `power_fault`, `total_energy`, `outage_time`, `compressor_health` | `power_fault`, `pressure_stability` |

Optional global tags for every PLC:
`enable_machine`, `speed_factor`, `fault_injection`, `availability`, `performance`, `quality`, `oee`.
