#!/bin/bash

# Name: Kubernetes Copy Secret
# Description: Copies a Kubernetes secret from one context/namespace to another

VERSION="1.0.0"
LOG_FILE="$(dirname "$0")/secret_copy_$(date +%Y%m%d_%H%M%S).log"

# 🎨 Colors and formatting
BOLD=$(tput bold)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# 📢 Help function
show_help() {
  echo "${BOLD}${BLUE}Kubernetes Copy Secret ${RESET}${GREEN}v$VERSION${RESET}"
  echo "Usage: $0 [options] <secret-name> <source-context> <target-context>"
  echo "       $0 [options] <secret-name> <source-context> <source-namespace> <target-context> <target-namespace>"
  echo ""
  echo "${BOLD}🔧 Options:${RESET}"
  echo "  -h, --help          Show this help message"
  echo "  -v, --verbose       Enable verbose output"
  echo "  -d, --dry-run       Show what would be done without making changes"
  echo "  -l, --log           Enable logging to file ($LOG_FILE)"
  echo "  -f, --force         Overwrite secret in target if it exists"
  echo ""
  echo "${BOLD}📌 Examples:${RESET}"
  echo "  ${BLUE}Basic usage:${RESET}"
  echo "  $0 my-secret ctx-source ctx-target"
  echo ""
  echo "  ${BLUE}With namespaces:${RESET}"
  echo "  $0 my-secret ctx-source ns-source ctx-target ns-target"
  echo ""
  echo "  ${BLUE}With options:${RESET}"
  echo "  $0 -v -l my-secret ctx-source ctx-target"
  exit 0
}

# 📝 Logging function
log() {
  local message="$1"
  local timestamp=$(date +"%Y-%m-%d %T")
  
  if [ "$VERBOSE" = true ]; then
    echo -e "${BOLD}${BLUE}[${timestamp}]${RESET} ${message}"
  fi
  
  if [ "$LOGGING" = true ]; then
    echo "[${timestamp}] ${message}" >> "$LOG_FILE"
  fi
}

# ⚠️ Error handler
error_exit() {
  local message="$1"
  log "${RED}❌ ERROR: ${message}${RESET}"
  echo "${RED}${BOLD}⛔ Error: ${message}${RESET}" >&2
  exit 1
}

# 🔄 Progress indicator
show_progress() {
  local pid=$!
  local spin='-\|/'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %4 ))
    printf "\r${BLUE}${spin:$i:1} ${1}...${RESET}"
    sleep 0.1
  done
  printf "\r${GREEN}✓ ${1} complete${RESET}\n"
}

# 🔍 Check dependencies
check_dependencies() {
  log "${YELLOW}🔍 Checking dependencies...${RESET}"
  local missing=0
  
  if ! command -v kubectl &> /dev/null; then
    error_exit "kubectl is not installed. Please install kubectl."
  fi
  
  if ! command -v jq &> /dev/null; then
    error_exit "jq is not installed. Please install jq (brew install jq / apt-get install jq)."
  fi
  
  log "${GREEN}✅ All dependencies are available${RESET}"
}

# Parse arguments
VERBOSE=false
DRY_RUN=false
LOGGING=false
FORCE=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) show_help ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -d|--dry-run) DRY_RUN=true; shift ;;
    -l|--log) LOGGING=true; shift ;;
    -f|--force) FORCE=true; shift ;;
    *) break ;;
  esac
done

# Check remaining arguments (either 3 or 5)
if [[ "$#" -ne 3 && "$#" -ne 5 ]]; then
  error_exit "Invalid number of arguments. See --help for usage."
fi

# Assign arguments based on count
if [[ "$#" -eq 3 ]]; then
  SECRET_NAME=$1
  SOURCE_CONTEXT=$2
  TARGET_CONTEXT=$3
  SOURCE_NAMESPACE="default"
  TARGET_NAMESPACE="default"
else
  SECRET_NAME=$1
  SOURCE_CONTEXT=$2
  SOURCE_NAMESPACE=$3
  TARGET_CONTEXT=$4
  TARGET_NAMESPACE=$5
fi

# 🏁 Start execution
echo "${BOLD}${GREEN}🌟 Kubernetes Secret Copier v$VERSION${RESET}"
log "${BOLD}🚀 Starting secret copy operation${RESET}"
log "Secret: ${SECRET_NAME}"
log "Source: context=${SOURCE_CONTEXT}, namespace=${SOURCE_NAMESPACE}"
log "Target: context=${TARGET_CONTEXT}, namespace=${TARGET_NAMESPACE}"
log "Options: verbose=${VERBOSE}, dry-run=${DRY_RUN}, log=${LOGGING}, force=${FORCE}"

check_dependencies

# 🔎 Verify source context exists
log "${YELLOW}🔍 Validating source context...${RESET}"
if ! kubectl config get-contexts -o name | grep -q "^${SOURCE_CONTEXT}$"; then
  error_exit "Source context '${SOURCE_CONTEXT}' not found in kubeconfig"
fi

# 🔎 Verify target context exists
log "${YELLOW}🔍 Validating target context...${RESET}"
if ! kubectl config get-contexts -o name | grep -q "^${TARGET_CONTEXT}$"; then
  error_exit "Target context '${TARGET_CONTEXT}' not found in kubeconfig"
fi

# 📦 Fetch the secret
log "${YELLOW}📦 Fetching secret from source...${RESET}"
SECRET_JSON=$(kubectl --context="$SOURCE_CONTEXT" get secret "$SECRET_NAME" -n "$SOURCE_NAMESPACE" -o json 2>&1) &
show_progress "Fetching secret from source"

if [ -z "$SECRET_JSON" ]; then
  error_exit "Secret '${SECRET_NAME}' not found in context '${SOURCE_CONTEXT}' and namespace '${SOURCE_NAMESPACE}'"
fi

# Check if secret exists in target
log "${YELLOW}🔍 Checking if secret exists in target...${RESET}"
if kubectl --context="$TARGET_CONTEXT" get secret "$SECRET_NAME" -n "$TARGET_NAMESPACE" &>/dev/null; then
  if [ "$FORCE" = false ]; then
    error_exit "Secret already exists in target. Use -f to force overwrite."
  else
    log "${YELLOW}⚠️ Secret exists in target - will overwrite due to --force${RESET}"
  fi
fi

# ✂️ Process the secret JSON
log "${YELLOW}✂️ Processing secret data...${RESET}"
SECRET_JSON=$(echo "$SECRET_JSON" | jq 'del(.metadata.namespace, .metadata.resourceVersion, .metadata.uid, .metadata.creationTimestamp, .metadata.annotations."kubectl.kubernetes.io/last-applied-configuration")') &
show_progress "Processing secret data"

if [ -z "$SECRET_JSON" ]; then
  error_exit "Error processing the secret JSON"
fi

# Check secret type
SECRET_TYPE=$(echo "$SECRET_JSON" | jq -r '.type')
if [ "$SECRET_TYPE" != "Opaque" ]; then
  log "${YELLOW}⚠️ Warning: Secret type is '${SECRET_TYPE}' (not Opaque)${RESET}"
fi

# 🚦 Dry-run check
if [ "$DRY_RUN" = true ]; then
  echo "${BOLD}${YELLOW}🚦 Dry-run mode - would apply this secret:${RESET}"
  echo "$SECRET_JSON" | jq
  echo ""
  echo "${GREEN}✅ Dry-run complete - no changes made${RESET}"
  exit 0
fi

# ✈️ Apply the secret
log "${YELLOW}✈️ Applying secret to target...${RESET}"
echo "$SECRET_JSON" | kubectl --context="$TARGET_CONTEXT" apply -n "$TARGET_NAMESPACE" -f - &
show_progress "Applying secret to target"

if [ $? -eq 0 ]; then
  log "${GREEN}✅ Secret '${SECRET_NAME}' successfully copied to context '${TARGET_CONTEXT}' and namespace '${TARGET_NAMESPACE}'${RESET}"
  echo "${BOLD}${GREEN}🎉 Success! Secret copied successfully.${RESET}"
else
  error_exit "Failed to apply the secret to target"
fi

# 📊 Final report
if [ "$LOGGING" = true ]; then
  echo "${BLUE}📋 Log file created: ${LOG_FILE}${RESET}"
fi
