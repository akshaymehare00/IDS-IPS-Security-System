#!/bin/bash

# Test script for Suricata IDS/IPS
echo "Starting Suricata IDS/IPS tests..."

# Check if Suricata is running
echo "Checking Suricata service status..."
if systemctl is-active --quiet suricata; then
    echo "✅ Suricata is running"
else
    echo "❌ Suricata is not running! Try starting it with: sudo systemctl start suricata"
    exit 1
fi

# Check Suricata configuration
echo "Checking Suricata configuration..."
if suricata -T -c /etc/suricata/suricata.yaml 2>/dev/null; then
    echo "✅ Suricata configuration is valid"
else
    echo "❌ Suricata configuration has errors!"
fi

# Test SQL Injection detection
echo "Testing SQL Injection detection..."
curl -s "http://localhost/?id=1' OR '1'='1" > /dev/null
echo "Check logs for SQL injection alerts: sudo tail -f /var/log/suricata/fast.log"

# Test XSS detection
echo "Testing XSS detection..."
curl -s "http://localhost/?xss=<script>alert(1)</script>" > /dev/null
echo "Check logs for XSS alerts: sudo tail -f /var/log/suricata/fast.log"

# Test suspicious user agent
echo "Testing suspicious user agent detection..."
curl -s -A "sqlmap/1.0" "http://localhost/" > /dev/null
echo "Check logs for suspicious user agent alerts: sudo tail -f /var/log/suricata/fast.log"

echo "Suricata tests complete. Check the logs to ensure alerts were generated."
echo "Run: sudo tail -f /var/log/suricata/fast.log"

exit 0 