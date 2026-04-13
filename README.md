# OpenPLC Headless Orchestrator

This project provides a simple way to programmatically create and manage OpenPLC instances using Docker. It allows users to upload Structured Text (ST) programs, compile them, and start PLC runtimes without using the OpenPLC UI.

This component is part of the **Taksa FactoryOS** project and is intended to support **factory simulation environments**. Using this, one can spin up multiple PLCs and simulate machines, production lines, or entire factories.

---

## Overview

The tool automates the full lifecycle of a PLC:

1. Start OpenPLC in a Docker container
2. Upload an ST program
3. Compile the program
4. Start the PLC

Multiple PLCs can be created by assigning different names, IPs, and ports.


---

## Prerequisites

* Docker and Docker Compose
* Python 3.8+
* Python dependency:

TODO: add proper requirements.txt

```bash
pip install requests
```

---

## Usage

Run a PLC with a given ST program:

```bash
python3 plc_manager.py \
  --ip 10.10.10.11 \
  --port 8081 \
  --plc-name plc1 \
  --st-file program.st
```

Stop and remove a running PLC instance:

```bash
python3 plc_manager.py \
  --ip 10.10.10.11 \
  --port 8081 \
  --plc-name plc1 \
  --down
```

---

## Access

Once deployed:

```
docker logs <plc_name>

```
You can also use UI, if needed

```
http://<IP>:<PORT>
```

Example:

```
http://10.10.10.11:8081
```

---

## Notes

* OpenPLC v3 is UI-driven; this tool mimics browser interactions
* Program upload is a multi-step process handled internally
* Each PLC instance must use a unique IP and port

---

## Use Case

This tool enables:

* Simulation of multiple PLC-controlled machines
* Building digital factory environments
* Testing PLC logic at scale
* Integration with higher-level systems such as FactoryOS

---

## Context

This repository is a building block of **Taksa FactoryOS**, which aims to provide an open, programmable factory operating system for simulation and automation use cases.

---


