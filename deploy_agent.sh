#!/usr/bin/env bash
# deploy_agent.sh - deploy, run and archive the attendance tracker

check_tools() {
    for tool in python3 zip; do
        if ! command -v "$tool" > /dev/null 2>&1; then
            echo "Error: $tool is not installed. Install it and try again."
            exit 1
        fi
    done
    python3 --version
}

deploy() {
    echo "deploy: not written yet"
}

run_app() {
    echo "run: not written yet"
}

archive_logs() {
    echo "archive: not written yet"
}

check_tools

echo "1) Deploy a new project"
echo "2) Run an existing project"
echo "3) Archive logs"
echo "4) Quit"
read -r -p "Pick one: " choice

case "$choice" in
    1) deploy ;;
    2) run_app ;;
    3) archive_logs ;;
    4) exit 0 ;;
    *) echo "Invalid choice" ;;
esac
