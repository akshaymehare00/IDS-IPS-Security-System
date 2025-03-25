# Testing Your Security System

This document provides instructions for testing your IDS/IPS system to ensure it's working correctly and effectively protecting your server.

## Prerequisites

Before running tests, make sure:

1. All services are running: Suricata, OSSEC, Nginx (with ModSecurity), and Fail2ban
2. Your security system is fully installed and configured
3. You have root/sudo access to the server

## Quick Start

For a complete health check of your entire system, run:

```bash
sudo chmod +x test-security-system.sh
sudo ./test-security-system.sh
```

This will run all tests and provide a comprehensive report of your security system's status.

## Component-Specific Tests

### 1. Testing Suricata (Network IDS/IPS)

The `test-suricata.sh` script simulates common web attacks to verify that Suricata is detecting and blocking malicious traffic.

```bash
sudo chmod +x test-suricata.sh
sudo ./test-suricata.sh
```

After running the script, check Suricata's alert log:

```bash
sudo tail -f /var/log/suricata/fast.log
```

**Expected Results:** You should see alerts for SQL injection, XSS attacks, and suspicious user agents.

### 2. Testing ModSecurity (Web Application Firewall)

The `test-modsecurity.sh` script tests ModSecurity's ability to detect and block web application attacks.

```bash
sudo chmod +x test-modsecurity.sh
sudo ./test-modsecurity.sh
```

Check ModSecurity alerts in the Nginx error log:

```bash
sudo grep -i modsec /var/log/nginx/error.log
```

**Expected Results:** You should see ModSecurity alerts for SQL injection, XSS, command injection, and other attack types.

### 3. Testing OSSEC (Host-based IDS)

The `test-ossec.sh` script tests OSSEC's file integrity monitoring and log analysis capabilities.

```bash
sudo chmod +x test-ossec.sh
sudo ./test-ossec.sh
```

Check OSSEC alerts:

```bash
sudo tail -f /var/ossec/logs/alerts/alerts.log
```

**Expected Results:** You should see alerts for file modifications and authentication failures.

### 4. Testing Fail2ban

The `test-fail2ban.sh` script tests Fail2ban's ability to detect and block brute force attacks.

```bash
sudo chmod +x test-fail2ban.sh
sudo ./test-fail2ban.sh
```

Check Fail2ban status:

```bash
sudo fail2ban-client status
```

**Expected Results:** You should see active jails and possibly banned IPs (depending on your configuration).

## Performance Benchmarking

To evaluate the performance impact of your security system:

```bash
sudo chmod +x benchmark-security.sh
sudo ./benchmark-security.sh
```

This will measure:
- Request throughput with all security components active
- Request throughput with individual components disabled
- Overall performance impact of the security system

**Note:** Only run the benchmark on test/staging environments, as it temporarily disables security components.

## Manual Testing

### Testing Suricata Manually

1. Simulate an SQL injection attack:
   ```bash
   curl "http://your-server/?id=1' OR '1'='1"
   ```

2. Simulate an XSS attack:
   ```bash
   curl "http://your-server/?xss=<script>alert(1)</script>"
   ```

3. Check the logs:
   ```bash
   sudo tail -f /var/log/suricata/fast.log
   ```

### Testing ModSecurity Manually

1. Simulate a directory traversal attack:
   ```bash
   curl "http://your-server/?file=../../../etc/passwd"
   ```

2. Simulate an SQL injection attack:
   ```bash
   curl "http://your-server/?id=1 UNION SELECT username,password FROM users"
   ```

3. Check the logs:
   ```bash
   sudo grep -i modsec /var/log/nginx/error.log
   ```

### Testing Fail2ban Manually

1. Attempt multiple failed SSH logins (from another server):
   ```bash
   ssh nonexistent_user@your-server
   ```
   Repeat this several times with incorrect passwords.

2. Check if the IP gets banned:
   ```bash
   sudo fail2ban-client status sshd
   ```

## Troubleshooting

### Suricata Issues

- If no alerts appear:
  ```bash
  sudo suricata -T -c /etc/suricata/suricata.yaml  # Test config
  sudo systemctl restart suricata                 # Restart service
  sudo tail -f /var/log/suricata/suricata.log      # Check for errors
  ```

### ModSecurity Issues

- If ModSecurity isn't blocking attacks:
  ```bash
  sudo nginx -t                                   # Test Nginx config
  sudo grep -i modsec /var/log/nginx/error.log    # Check for activation
  ```
  
- Verify ModSecurity is enabled:
  ```bash
  grep -r "modsecurity on" /etc/nginx/
  ```

### OSSEC Issues

- If OSSEC isn't detecting changes:
  ```bash
  sudo /var/ossec/bin/ossec-control status        # Check status
  sudo /var/ossec/bin/ossec-syscheckd -t          # Test syscheck
  sudo cat /var/ossec/logs/ossec.log              # Check for errors
  ```

### Fail2ban Issues

- If Fail2ban isn't banning IPs:
  ```bash
  sudo fail2ban-client status                     # Check status
  sudo cat /var/log/fail2ban.log                  # Check for errors
  sudo iptables -L -n                             # Check firewall rules
  ```

## Verifying Dashboard Access

Check if the security dashboard is accessible:

```bash
curl -I http://your-server-ip:8080/security-dashboard/
```

You should receive a 200 OK response.

## Additional Tests

### Testing HTTPS Security

If you've configured HTTPS, test your SSL/TLS security:

```bash
curl https://www.ssllabs.com/ssltest/analyze.html?d=your-domain.com
```

### Testing Overall Web Security

Test your overall web security posture:

```bash
curl https://observatory.mozilla.org/analyze/your-domain.com
```

## Conclusion

Your security system should detect and block common attack vectors. If any component is not working as expected, review its configuration files and logs. The GUIDE.md file contains detailed troubleshooting steps for each component.

Remember that security is an ongoing process. Regularly update your system and security rules to protect against new threats. 