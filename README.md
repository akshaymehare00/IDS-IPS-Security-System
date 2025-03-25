# IDS/IPS Security Testing Framework

A comprehensive suite of testing scripts for validating and benchmarking intrusion detection and prevention systems.

## Overview

This repository contains a collection of shell scripts designed to test and verify the functionality of various security components:

- Suricata IDS/IPS
- ModSecurity Web Application Firewall
- OSSEC Host-based Intrusion Detection
- Fail2ban Intrusion Prevention

## Components

- `test-security-system.sh` - Main script that checks all components
- `test-suricata.sh` - Tests Suricata IDS/IPS functionality
- `test-modsecurity.sh` - Tests ModSecurity WAF rules
- `test-ossec.sh` - Tests OSSEC file integrity and log monitoring
- `test-fail2ban.sh` - Tests Fail2ban's ability to block brute force attempts
- `benchmark-security.sh` - Measures performance impact of security components
- `TESTING.md` - Detailed testing instructions and expected results

## Usage

For a full system test:
```bash
sudo ./test-security-system.sh
```

See `TESTING.md` for detailed usage instructions for each component.

## License

MIT 