#!/bin/bash

# Test script for OSSEC HIDS
echo "Starting OSSEC HIDS tests..."

# Check if OSSEC is running
echo "Checking OSSEC service status..."
if /var/ossec/bin/ossec-control status | grep -q "is running"; then
    echo "✅ OSSEC is running"
else
    echo "❌ OSSEC is not running! Try starting it with: sudo /var/ossec/bin/ossec-control start"
    exit 1
fi

# Create a temporary test file in a monitored directory
echo "Testing file integrity monitoring..."
TEST_FILE="/etc/ossec_test_file.txt"
echo "This is a test file for OSSEC" > $TEST_FILE
echo "Created test file: $TEST_FILE"
echo "Wait a few minutes and check OSSEC logs for file integrity alerts"

# Simulate failed authentication attempts
echo "Testing authentication failure detection..."
# This just simulates the log entry
echo "$(date +"%b %d %H:%M:%S") localhost sshd[12345]: Failed password for invalid user baduser from 192.168.1.100 port 12345 ssh2" | sudo tee -a /var/log/auth.log > /dev/null
echo "Added simulated SSH authentication failure to auth.log"

# Force log analysis check
echo "Forcing immediate log analysis check..."
sudo /var/ossec/bin/ossec-logtest -t > /dev/null 2>&1
sudo /var/ossec/bin/ossec-maild -t > /dev/null 2>&1
sudo /var/ossec/bin/ossec-analysisd -t > /dev/null 2>&1

# Test rootcheck functionality
echo "Testing rootcheck functionality..."
# Create a simulated suspicious file in tmp directory
echo "#!/bin/bash\necho 'test rootkit' > /dev/null" | sudo tee /tmp/suspicious_file.sh > /dev/null
sudo chmod +x /tmp/suspicious_file.sh
echo "Created suspicious test file in /tmp. Check OSSEC logs for alerts."

echo "OSSEC tests initiated. Check the logs after a few minutes for alerts:"
echo "sudo tail -f /var/ossec/logs/alerts/alerts.log"

echo "Note: OSSEC runs checks at set intervals, so alerts might not appear immediately."
echo "Clean up test file? (y/n)"
read -r answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    rm -f $TEST_FILE
    rm -f /tmp/suspicious_file.sh
    echo "Test files removed"
fi

exit 0 