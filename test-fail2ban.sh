#!/bin/bash

# Test script for Fail2ban
echo "Starting Fail2ban tests..."

# Check if Fail2ban is running
echo "Checking Fail2ban service status..."
if systemctl is-active --quiet fail2ban; then
    echo "✅ Fail2ban is running"
else
    echo "❌ Fail2ban is not running! Try starting it with: sudo systemctl start fail2ban"
    exit 1
fi

# List all jails
echo "Checking active jails..."
ACTIVE_JAILS=$(fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,//g')
if [ -z "$ACTIVE_JAILS" ]; then
    echo "❌ No active jails found! Check your Fail2ban configuration."
else
    echo "✅ Active jails: $ACTIVE_JAILS"
fi

# Testing detection capabilities

# 1. Simulate SSH failed login attempts
echo "Testing SSH brute force detection..."
echo "Simulating SSH failed logins (safe test)..."
for i in {1..3}; do
    echo "$(date +"%b %d %H:%M:%S") localhost sshd[12345]: Failed password for invalid user testuser from 192.168.100.100 port 12345 ssh2" | sudo tee -a /var/log/auth.log > /dev/null
done
echo "Simulated SSH login failures added to /var/log/auth.log"

# 2. Simulate HTTP authentication failures
echo "Testing HTTP authentication failure detection..."
echo "$(date +"[%d/%b/%Y:%H:%M:%S %z]") 192.168.100.101 - - \"GET /restricted HTTP/1.1\" 401 123" | sudo tee -a /var/log/nginx/access.log > /dev/null
echo "Simulated HTTP auth failure added to nginx access log"

# 3. Simulate WordPress login attempts
echo "Testing WordPress login protection..."
echo "$(date +"[%d/%b/%Y:%H:%M:%S %z]") 192.168.100.102 - - \"POST /wp-login.php HTTP/1.1\" 200 123" | sudo tee -a /var/log/nginx/access.log > /dev/null
echo "Simulated WordPress login attempt added to nginx access log"

# Give Fail2ban time to process the logs
echo "Giving Fail2ban time to process (5 seconds)..."
sleep 5

# Check if any bans were triggered
echo "Checking for triggered bans..."
BANNED_IPS=$(sudo fail2ban-client status all | grep "IP list:" | grep -v "IP list:.*[]" | wc -l)
if [ "$BANNED_IPS" -gt 0 ]; then
    echo "✅ Fail2ban successfully detected and banned IPs!"
    echo "Banned IP details:"
    sudo fail2ban-client status all | grep -A1 "IP list:" | grep -v "IP list:.*[]"
else
    echo "⚠️ No bans detected. This could be normal depending on your Fail2ban configuration."
    echo "Check your Fail2ban logs for more details: sudo tail -f /var/log/fail2ban.log"
    echo "Note: Some jails might require more failed attempts than we simulated."
fi

echo "To manually check all banned IPs, run: sudo fail2ban-client status"
echo "To check specific jail status, run: sudo fail2ban-client status sshd"

exit 0 