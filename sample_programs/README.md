# Sample ST Programs (15 PLCs)

Programs location: `sample_programs/`

RO = live read tags, RW = control/write tags.

1. **PLC-1** | `RawMaterialHandling.st` | Raw material feed and availability  
RO: `material_feed_rate`, `material_available`, `material_composition_ok`, `overload_alarm`, `energy_usage_conveyor`, `feeder_idle_time`, `motor_health`  
RW: `material_available`, `material_composition_ok`

2. **PLC-2** | `MeltingFurnace.st` | Furnace melt and alloy behavior  
RO: `melt_rate`, `tap_time`, `metal_temperature`, `composition`, `overheat_alarm`, `energy_consumption`, `furnace_downtime`, `refractory_health`  
RW: `metal_temperature`, `composition`

3. **PLC-3** | `Degassing.st` | Degassing quality and gas behavior  
RO: `treatment_cycle_time`, `gas_content_level`, `gas_leak_alarm`, `gas_consumption`, `idle_time`, `rotor_health`  
RW: `gas_content_level`

4. **PLC-4** | `Press.st` | Casting/forging press throughput and defects  
RO: `cycle_time`, `parts_per_hour`, `porosity_flag`, `fill_quality`, `pressure_alarm`, `hydraulic_energy`, `press_idle_time`, `press_load`, `die_health`  
RW: `press_load`, `fill_quality`

5. **PLC-5** | `Cooling.st` | Cooling stability and flow  
RO: `cooling_time`, `cooling_uniformity`, `temp_alarm`, `water_usage`, `blockage_time`, `pump_health`  
RW: `cooling_uniformity`

6. **PLC-6** | `HeatTreatment.st` | Heat treatment profile and hardness impact  
RO: `batch_cycle_time`, `hardness`, `temperature_profile`, `furnace_alarm`, `fuel_consumption`, `downtime`, `heater_health`  
RW: `temperature_profile`

7. **PLC-7** | `ShotBlasting.st` | Surface cleaning and blasting health  
RO: `cycle_time`, `surface_cleanliness`, `vibration_alarm`, `media_usage`, `jam_time`, `turbine_health`  
RW: `surface_cleanliness`

8. **PLC-8** | `CNCMachiningPLC8.st` | CNC machining line  
RO: `cycle_time`, `throughput`, `dimension_ok`, `surface_finish`, `tool_break_alarm`, `spindle_energy`, `machine_idle`, `spindle_load`, `tool_life`  
RW: `spindle_load`, `tool_life`

9. **PLC-9** | `CNCMachiningPLC9.st` | CNC machining line  
RO: `cycle_time`, `throughput`, `dimension_ok`, `surface_finish`, `tool_break_alarm`, `spindle_energy`, `machine_idle`, `spindle_load`, `tool_life`  
RW: `spindle_load`, `tool_life`

10. **PLC-10** | `CNCMachiningPLC10.st` | CNC machining line  
RO: `cycle_time`, `throughput`, `dimension_ok`, `surface_finish`, `tool_break_alarm`, `spindle_energy`, `machine_idle`, `spindle_load`, `tool_life`  
RW: `spindle_load`, `tool_life`

11. **PLC-11** | `Inspection.st` | Inline defect inspection  
RO: `inspection_rate`, `defect_detected`, `defect_type`, `camera_fault`, `system_energy`, `inspection_delay`, `camera_health`  
RW: `defect_detected`, `camera_fault`

12. **PLC-12** | `Painting.st` | Surface finishing and paint quality  
RO: `coating_rate`, `thickness`, `finish_quality`, `oven_alarm`, `powder_usage`, `energy`, `line_stop_time`, `nozzle_health`  
RW: `thickness`, `finish_quality`

13. **PLC-13** | `FinalInspection.st` | Final quality gate  
RO: `inspection_cycle`, `crack_detected`, `pass_fail`, `radiation_alarm`, `energy_usage`, `reinspection_time`, `sensor_health`  
RW: `crack_detected`, `pass_fail`

14. **PLC-14** | `Packing.st` | Packing and dispatch readiness  
RO: `packing_rate`, `packing_ok`, `jam_alarm`, `material_usage`, `downtime`, `robot_health`  
RW: `packing_ok`

15. **PLC-15** | `Utilities.st` | Plant utilities and global stability  
RO: `supply_rate`, `pressure_stability`, `power_fault`, `total_energy`, `outage_time`, `compressor_health`  
RW: `power_fault`, `pressure_stability`

Optional global tags for every PLC:  
`enable_machine`, `speed_factor`, `fault_injection`, `availability`, `performance`, `quality`, `oee`
