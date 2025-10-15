#!/bin/bash

DELAY=1       # seconds between snapshots
SNAPSHOT1="/tmp/snapshot1_$$"
SNAPSHOT2="/tmp/snapshot2_$$"

# Array to store register states and which ones have ever changed
declare -A register_history
declare -A registers_that_changed
declare -A register_value_history  # Store last 10 values for each register

# Cleanup function
cleanup() {
    echo "Cleaning up..."
    rm -f "$SNAPSHOT1" "$SNAPSHOT2"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo "Monitoring modbus registers..."
echo "Press Ctrl+C to stop."
sleep 2

# Take initial snapshot
mbpoll -1 -m rtu -b 9600 -P none -a 1 -r 1 -c 100 /dev/ttyUSB0 -t 3 > "$SNAPSHOT1"

if [ ! -s "$SNAPSHOT1" ]; then
    echo "Failed to get initial reading. Check your modbus connection."
    exit 1
fi

# Initialize register history
while IFS= read -r line; do
    reg=$(echo "$line" | awk '{print $1}' | tr -d '[]:"')
    val=$(echo "$line" | awk '{print $2}')
    # Only initialize if reg is a valid number and val is numeric
    if [[ "$reg" =~ ^[0-9]+$ && "$val" =~ ^[0-9]+$ ]]; then
        register_history["$reg"]="$val"
        register_value_history["$reg"]="$val"  # Initialize with first value
    fi
done < "$SNAPSHOT1"

# Main monitoring loop
while true; do
    sleep $DELAY
    
    # Take new snapshot
    mbpoll -1 -m rtu -b 9600 -P none -a 1 -r 1 -c 100 /dev/ttyUSB0 -t 3 > "$SNAPSHOT2"
    
    if [ ! -s "$SNAPSHOT2" ]; then
        continue
    fi
    
    # Check for changes and update history
    changes_occurred=false
    while IFS= read -r line; do
        reg=$(echo "$line" | awk '{print $1}' | tr -d '[]:"')
        val=$(echo "$line" | awk '{print $2}')
        
        # Only process if reg is a valid number and val is numeric
        if [[ "$reg" =~ ^[0-9]+$ && "$val" =~ ^[0-9]+$ ]]; then
            if [[ "${register_history["$reg"]}" != "$val" ]]; then
                register_history["$reg"]="$val"
                registers_that_changed["$reg"]=1  # Mark this register as having changed
                
                # Update value history - keep last 10 values
                current_history="${register_value_history["$reg"]}"
                if [[ -n "$current_history" ]]; then
                    # Add new value and keep only last 10
                    new_history="$current_history $val"
                    # Split into array and keep last 10
                    IFS=' ' read -ra hist_array <<< "$new_history"
                    if [ ${#hist_array[@]} -gt 10 ]; then
                        hist_array=("${hist_array[@]:$((${#hist_array[@]}-10))}")
                    fi
                    register_value_history["$reg"]="${hist_array[*]}"
                else
                    register_value_history["$reg"]="$val"
                fi
                
                changes_occurred=true
            fi
        fi
    done < "$SNAPSHOT2"
    
    # Always redraw the screen if we have registers that have changed
    if [ ${#registers_that_changed[@]} -gt 0 ]; then
        clear
        echo "Modbus Register Monitor - $(date +%H:%M:%S)"
        echo "=================================================================="
        echo "Register        Last 10 Values"
        echo "=================================================================="
        
        # Display only registers that have ever changed, sorted by register number
        for reg in $(printf '%s\n' "${!registers_that_changed[@]}" | sort -n); do
            history_values="${register_value_history["$reg"]}"
            # Format the history values with proper spacing and fixed-width columns
            formatted_history=""
            for val in $history_values; do
                if [[ -n "$formatted_history" ]]; then
                    formatted_history="$formatted_history -> $(printf "%5s" "$val")"
                else
                    formatted_history="$(printf "%5s" "$val")"
                fi
            done
            printf "%-15s %s\n" "Register $reg:" "$formatted_history"
        done
    fi
    
    # Update snapshot for next iteration
    mv "$SNAPSHOT2" "$SNAPSHOT1"
done
