#!/bin/bash

# Benchmark script for security system
# This script measures the performance impact of the security system

# Colors for better output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}  SECURITY SYSTEM PERFORMANCE BENCHMARK  ${NC}"
echo -e "${BLUE}======================================================${NC}"
echo ""

# Check required tools
echo -e "${YELLOW}Checking for required tools...${NC}"
for tool in ab grep awk dstat curl; do
    if ! command -v $tool &> /dev/null; then
        echo -e "${RED}❌ Required tool '$tool' is not installed.${NC}"
        echo "Please install it: sudo apt-get install $tool"
        exit 1
    fi
done
echo -e "${GREEN}✅ All required tools are installed${NC}"

# Function to measure resource usage
measure_resources() {
    echo -e "${YELLOW}Measuring resource usage for $1...${NC}"
    
    # Start dstat in background for 10 seconds, outputting to a file
    dstat --time --cpu --mem --net --disk --output "$1-resource-usage.csv" 1 10 &>/dev/null &
    DSTAT_PID=$!
    
    # Wait for dstat to finish
    sleep 11
    
    # Ensure dstat is stopped
    if ps -p $DSTAT_PID > /dev/null; then
        kill $DSTAT_PID 2>/dev/null
    fi
    
    echo -e "${GREEN}✅ Resource measurements saved to $1-resource-usage.csv${NC}"
}

# Function to conduct HTTP benchmark
http_benchmark() {
    name=$1
    url=$2
    concurrency=$3
    requests=$4
    
    echo -e "\n${BLUE}======================================================${NC}"
    echo -e "${BLUE}  HTTP BENCHMARK: $name  ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    
    echo -e "${YELLOW}Running benchmark with concurrency=$concurrency, requests=$requests${NC}"
    
    # Start resource measurement
    measure_resources "http-$name" &
    
    # Run Apache Bench
    ab -c $concurrency -n $requests $url > "http-$name-benchmark.txt"
    
    # Extract key results
    requests_per_second=$(grep "Requests per second" "http-$name-benchmark.txt" | awk '{print $4}')
    time_per_request=$(grep "Time per request" "http-$name-benchmark.txt" | head -1 | awk '{print $4}')
    failed_requests=$(grep "Failed requests" "http-$name-benchmark.txt" | awk '{print $3}')
    
    echo -e "${GREEN}Benchmark complete:${NC}"
    echo -e "  Requests per second: ${BLUE}$requests_per_second${NC}"
    echo -e "  Time per request: ${BLUE}$time_per_request ms${NC}"
    echo -e "  Failed requests: ${BLUE}$failed_requests${NC}"
    echo -e "${GREEN}Full results saved to http-$name-benchmark.txt${NC}"
}

# Function to measure response time with different security components
measure_with_components() {
    name=$1
    disable_components=$2
    
    echo -e "\n${BLUE}======================================================${NC}"
    echo -e "${BLUE}  MEASURING WITH $name CONFIGURATION  ${NC}"
    echo -e "${BLUE}======================================================${NC}"
    
    # Disable components as specified
    if [ -n "$disable_components" ]; then
        echo -e "${YELLOW}Temporarily disabling: $disable_components${NC}"
        for component in $disable_components; do
            case $component in
                "suricata")
                    sudo systemctl stop suricata
                    ;;
                "ossec")
                    sudo /var/ossec/bin/ossec-control stop
                    ;;
                "modsecurity")
                    # Disable ModSecurity by commenting out the loading in nginx config
                    sudo sed -i 's/^\(.*modsecurity on.*\)/#\1/' /etc/nginx/conf.d/modsecurity.conf
                    sudo systemctl reload nginx
                    ;;
                "fail2ban")
                    sudo systemctl stop fail2ban
                    ;;
            esac
        done
    fi
    
    # Run the benchmark
    http_benchmark "$name" "http://localhost/" 10 1000
    
    # Re-enable components
    if [ -n "$disable_components" ]; then
        echo -e "${YELLOW}Re-enabling security components...${NC}"
        for component in $disable_components; do
            case $component in
                "suricata")
                    sudo systemctl start suricata
                    ;;
                "ossec")
                    sudo /var/ossec/bin/ossec-control start
                    ;;
                "modsecurity")
                    # Re-enable ModSecurity
                    sudo sed -i 's/^#\(.*modsecurity on.*\)/\1/' /etc/nginx/conf.d/modsecurity.conf
                    sudo systemctl reload nginx
                    ;;
                "fail2ban")
                    sudo systemctl start fail2ban
                    ;;
            esac
        done
    fi
}

# Main benchmark sequence
echo -e "${YELLOW}Starting benchmark sequence...${NC}"
echo -e "${RED}Note: This will temporarily disable security components to measure their impact.${NC}"
echo -e "${RED}Proceed only on a test/staging server, not in production!${NC}"
echo -e "${YELLOW}Continue? (y/n)${NC}"
read -r answer
if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Benchmark cancelled."
    exit 0
fi

# 1. Baseline with all security components active
measure_with_components "full-security" ""

# 2. Without ModSecurity
measure_with_components "without-modsecurity" "modsecurity"

# 3. Without Suricata
measure_with_components "without-suricata" "suricata"

# 4. Without any security components
measure_with_components "no-security" "suricata ossec modsecurity fail2ban"

# 5. Normal mode again (to verify everything is back to normal)
measure_with_components "full-security-final" ""

# Generate summary report
echo -e "\n${BLUE}======================================================${NC}"
echo -e "${BLUE}  BENCHMARK SUMMARY  ${NC}"
echo -e "${BLUE}======================================================${NC}"

echo -e "${YELLOW}Performance impact of security components:${NC}"

# Extract and display results
full_rps=$(grep "Requests per second" "http-full-security-benchmark.txt" | awk '{print $4}')
no_modsec_rps=$(grep "Requests per second" "http-without-modsecurity-benchmark.txt" | awk '{print $4}')
no_suricata_rps=$(grep "Requests per second" "http-without-suricata-benchmark.txt" | awk '{print $4}')
no_security_rps=$(grep "Requests per second" "http-no-security-benchmark.txt" | awk '{print $4}')
final_rps=$(grep "Requests per second" "http-full-security-final-benchmark.txt" | awk '{print $4}')

# Calculate percentage differences
modsec_impact=$(awk "BEGIN {print (($no_modsec_rps - $full_rps) / $no_modsec_rps) * 100}")
suricata_impact=$(awk "BEGIN {print (($no_suricata_rps - $full_rps) / $no_suricata_rps) * 100}")
total_impact=$(awk "BEGIN {print (($no_security_rps - $full_rps) / $no_security_rps) * 100}")

echo -e "Full security system: ${BLUE}$full_rps${NC} requests/sec"
echo -e "Without ModSecurity: ${BLUE}$no_modsec_rps${NC} requests/sec (${YELLOW}$(printf "%.1f" $modsec_impact)%${NC} impact)"
echo -e "Without Suricata: ${BLUE}$no_suricata_rps${NC} requests/sec (${YELLOW}$(printf "%.1f" $suricata_impact)%${NC} impact)"
echo -e "No security: ${BLUE}$no_security_rps${NC} requests/sec (${YELLOW}$(printf "%.1f" $total_impact)%${NC} total impact)"
echo -e "Final measurement: ${BLUE}$final_rps${NC} requests/sec"

echo -e "\n${GREEN}Benchmark complete! All measurements are saved to CSV and TXT files.${NC}"
echo -e "${YELLOW}Note: A higher performance impact means the security system is doing more work to protect your server.${NC}"
echo -e "${YELLOW}Consider these results alongside the security benefits provided.${NC}"

exit 0 