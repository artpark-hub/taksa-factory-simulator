# OpenPLC Deployment Architecture (M01-M15)

## Purpose
This document describes the deployment architecture for 15 PLC containers and how to deploy OpenPLC ZIP programs per machine.

Reference style: `umh-factory-demo` architecture documentation.

## System Topology


      └─ VM Host (Docker)
          └─ Docker network: 10.10.10.0/24
              ├─ openplc1  (10.10.10.1)
              ├─ openplc2  (10.10.10.2)
              ├─ ...
              └─ openplc15 (10.10.10.15)


## PLC/Machine Mapping (M01-M15)

| Project ID | Machine Name | PLC Container | Target IP | ZIP Program |
|---|---|---|---|---|
| M01_PLCSIM | m01-cnc-milling | openplc1 | 10.10.10.1 | /home/plc-sim/zip_machine1.zip |
| M02_PLCSIM | m02-cnc-turning | openplc2 | 10.10.10.2 | /home/plc-sim/zip_machine2.zip |
| M03_PLCSIM | m03-injection-molding | openplc3 | 10.10.10.3 | /home/plc-sim/zip_machine3.zip |
| M04_PLCSIM | m04-metal-forming | openplc4 | 10.10.10.4 | /home/plc-sim/zip_machine4.zip |
| M05_PLCSIM | m05-packaging | openplc5 | 10.10.10.5 | /home/plc-sim/zip_machine5.zip |
| M06_PLCSIM | m06-carton-sealing | openplc6 | 10.10.10.6 | /home/plc-sim/zip_machine6.zip |
| M07_PLCSIM | m07-robot-pick-place | openplc7 | 10.10.10.7 | /home/plc-sim/zip_machine7.zip |
| M08_PLCSIM | m08-robot-welder | openplc8 | 10.10.10.8 | /home/plc-sim/zip_machine8.zip |
| M09_PLCSIM | m09-spot-welder | openplc9 | 10.10.10.9 | /home/plc-sim/zip_machine9.zip |
| M10_PLCSIM | m10-assembly-station | openplc10 | 10.10.10.10 | /home/plc-sim/zip_machine10.zip |
| M11_PLCSIM | m11-vision-inspection | openplc11 | 10.10.10.11 | /home/plc-sim/zip_machine11.zip |
| M12_PLCSIM | m12-labeling-machine | openplc12 | 10.10.10.12 | /home/plc-sim/zip_machine12.zip |
| M13_PLCSIM | m13-palletizer | openplc13 | 10.10.10.13 | /home/plc-sim/zip_machine13.zip |
| M14_PLCSIM | m14-test-bench | openplc14 | 10.10.10.14 | /home/plc-sim/zip_machine14.zip |
| M15_PLCSIM | m15-conveyor-buffer | openplc15 | 10.10.10.15 | /home/plc-sim/zip_machine15.zip |

## Deployment Flow

1. Build PLC logic in OpenPLC.
2. Export program ZIP (`zip_machineX.zip`).
3. Place ZIP on VM (for example in `/home/plc-sim/`).
4. Run deployment script against target PLC IP.
5. Verify runtime status is `STATUS:RUNNING`.

## Script Command

The updated PLC ZIP files are available for deployment (`zip_machine1.zip` onward).

Example command:

bash
./openplc_run_and_deploy.sh 10.10.10.2 "/home/plc-sim/zip_machine3.zip"


Use the same format for other PLCs by changing:
- Target IP (`10.10.10.x`)
- ZIP file path (`/home/plc-sim/zip_machineX.zip`)

## Routing Setup (Laptop to Docker PLC Network)

For connectivity from your laptop to 10.10.10.x (containers running on VM), add route to 10.10.10.0/24 via <GATEWAY_IP>.

### macOS
bash
route -n add 10.10.10.0/24 <GATEWAY_IP>

### Linux
bash
route add -net 10.10.10.0/24 gw <GATEWAY_IP>


### Windows (PowerShell)
powershell
New-NetRoute -DestinationPrefix "10.10.10.0/24" -NextHop "<GATEWAY_IP>" -PolicyStore PersistentStore


## Operations Notes
- Keep ST code same across projects; only machine-specific parameters and ZIP differ.
- Prefer matching `zip_machineX.zip` to `openplcX` unless intentionally testing cross-load behavior.
- If connectivity fails, validate route first, then test reachability to target `10.10.10.x`.

