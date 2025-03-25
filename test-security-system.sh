#!/bin/bash

# Test script for the entire security system
# This script tests all components: Suricata, OSSEC, ModSecurity, and Fail2ban

# Colors for better output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
NC="\033[0m" # No Color

echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}  SECURITY SYSTEM TEST SUITE  ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo ""

# Function to check if a service is running
check_service() {
    service_name=$1
    check_command=$2
    
    echo -e "${YELLOW}Checking $service_name service status...${NC}"
    
    if eval "$check_command"; then
        echo -e "${GREEN}✅ $service_name is running correctly${NC}"
        return 0
    else
        echo -e "${RED}❌ $service_name is not running correctly${NC}"
        return 1
    fi
}

# Function to run a specific test and track results
run_test() {
    test_name=$1
    test_script=$2
    
    echo -e "\n${GREEN}======================================================${NC}"
    echo -e "${GREEN}  TESTING: $test_name  ${NC}"
    echo -e "${GREEN}======================================================${NC}"
    
    # Make the test script executable
    chmod +x "$test_script"
    
    # Run the test script
    ./"$test_script" 2>&1
    
    # Check the result
    if [ $? -eq 0 ]; then
        echo -e "\n${GREEN}[$test_name] Tests completed successfully${NC}"
        SUCCESSES=$((SUCCESSES+1))
    else
        echo -e "\n${RED}[$test_name] Tests failed${NC}"
        FAILURES=$((FAILURES+1))
    fi
}

# Function to check logs for recent entries
check_logs() {
    log_file=$1
    component=$2
    
    echo -e "\n${YELLOW}Checking $component logs ($log_file)...${NC}"
    
    if [ -f "$log_file" ]; then
        entries=$(sudo tail -n 10 "$log_file" | wc -l)
        if [ "$entries" -gt 0 ]; then
            echo -e "${GREEN}✅ $component logs exist and have recent entries${NC}"
            echo -e "Last few entries:"
            sudo tail -n 3 "$log_file"
        else
            echo -e "${RED}❌ $component logs exist but might not have recent entries${NC}"
        fi
    else
        echo -e "${RED}❌ $component log file not found${NC}"
    fi
}

# Track test results
SUCCESSES=0
FAILURES=0

# --- Check if all required services are running ---
echo -e "${YELLOW}Performing initial service checks...${NC}"

# Check Suricata
check_service "Suricata" "systemctl is-active --quiet suricata"

# Check OSSEC
check_service "OSSEC" "/var/ossec/bin/ossec-control status | grep -q 'is running'"

# Check Nginx (ModSecurity)
check_service "Nginx (ModSecurity)" "systemctl is-active --quiet nginx"

# Check Fail2ban
check_service "Fail2ban" "systemctl is-active --quiet fail2ban"

# --- Run individual component tests ---
run_test "Suricata IDS/IPS" "test-suricata.sh"
run_test "ModSecurity WAF" "test-modsecurity.sh"
run_test "OSSEC HIDS" "test-ossec.sh"
run_test "Fail2ban" "test-fail2ban.sh"

# --- Check logs for each component ---
check_logs "/var/log/suricata/fast.log" "Suricata"
check_logs "/var/ossec/logs/alerts/alerts.log" "OSSEC"
check_logs "/var/log/nginx/error.log" "ModSecurity (Nginx error log)"
check_logs "/var/log/fail2ban.log" "Fail2ban"

# --- Check dashboard access ---
echo -e "\n${YELLOW}Checking security dashboard...${NC}"
if curl -s --head http://localhost:8080/security-dashboard/ | grep "200 OK" > /dev/null; then
    echo -e "${GREEN}✅ Security dashboard is accessible${NC}"
else
    echo -e "${RED}❌ Security dashboard is not accessible${NC}"
    echo "Check Nginx configuration and PHP-FPM status"
fi

# --- Display summary ---
echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}  TEST SUMMARY  ${NC}"
echo -e "${GREEN}======================================================${NC}"
echo -e "Tests completed: $((SUCCESSES + FAILURES))"
echo -e "Successful: ${GREEN}$SUCCESSES${NC}"
echo -e "Failed: ${RED}$FAILURES${NC}"
echo ""

if [ $FAILURES -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Your security system appears to be working correctly.${NC}"
else
    echo -e "${RED}⚠️ Some tests failed. Review the output above to troubleshoot issues.${NC}"
fi

echo -e "\n${YELLOW}Next steps:${NC}"
echo "1. Review logs manually to ensure alerts are being generated"
echo "2. Check the security dashboard at http://your-server-ip:8080/security-dashboard/"
echo "3. Consult GUIDE.md for troubleshooting if needed"

exit 0 