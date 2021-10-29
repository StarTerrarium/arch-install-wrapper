# Colour definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Prints "DONE" in green, then sets colour back.
function print_done {
  echo -e "${GREEN}DONE${NC}"
}

# Prints "FAILED" in red, then sets colour back
function print_failed {
  echo -e "${RED}FAILED${NC}"
}

# Prints the red "FAILED" and optionally an extra message before exiting the script.
function fail {
  print_failed
  if [ -n "$1" ]; then
    echo "$1"
  fi
  exit 1
}
