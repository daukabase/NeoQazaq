#!/bin/bash

# Path to the counter file
COUNTER_FILE="counter.txt"

# Check if counter.txt exists, if not, create it with an initial value of 0
if [ ! -f "$COUNTER_FILE" ]; then
  echo "0" > $COUNTER_FILE
fi

# Read the current counter value
COUNTER=$(cat $COUNTER_FILE)

# Increment the counter
NEW_COUNTER=$((COUNTER + 1))

# Write the new counter value back to the file
echo $NEW_COUNTER > $COUNTER_FILE

# Output the new counter value for debugging
echo "Counter incremented to $NEW_COUNTER"
