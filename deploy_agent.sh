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
make_roster() {
    echo "1) Copy from template"
    echo "2) Generate a new roster"
    read -r -p "Roster option: " opt
    read -r -p "How many students? " count

    case "$count" in
        ''|*[!0-9]*) echo "Count must be a number."; return 1 ;;
    esac
    if [ "$count" -lt 1 ]; then
        echo "Need at least one student."
        return 1
    fi

    csv="$dir/Helpers/assets.csv"

    case "$opt" in
        1)
            total=$(($(grep -c '' templates/assets.csv) - 1))
            if [ "$count" -gt "$total" ]; then
                echo "Template only has $total students."
                return 1
            fi
            head -n $((count + 1)) templates/assets.csv > "$csv"
            ;;
        2)
            names=("Amina Bello" "Brian Otieno" "Chloe Dubois" "David Mensah" "Esther Kamau" "Felix Okoye" "Grace Uwase" "Hassan Ali" "Irene Mutesi" "James Kiptoo")
            if [ "$count" -gt "${#names[@]}" ]; then
                echo "I only have ${#names[@]} sample names."
                return 1
            fi
            echo "Email,Names,Attendance Count,Absence Count" > "$csv"
            i=0
            while [ "$i" -lt "$count" ]; do
                n="${names[$i]}"
                mail=$(echo "$n" | tr 'A-Z ' 'a-z.')
                echo "$mail@example.com,$n,0,0" >> "$csv"
                i=$((i + 1))
            done
            sed -i.bak 's/"total_sessions": 5/"total_sessions": 1/' "$dir/Helpers/config.json"
            rm "$dir/Helpers/config.json.bak"
            ;;
        *)
            echo "Pick 1 or 2."
            return 1
            ;;
    esac
    echo "Roster written: $csv"
}

deploy() {
    read -r -p "Project name: " name
    if [ -z "$name" ]; then
        echo "Name can't be empty."
        return
    fi
    dir="attendance_tracker_$name"

    if [ -d "$dir" ]; then
        read -r -p "$dir already exists. Overwrite? (y/n) " ans
        if [ "$ans" != "y" ]; then
            echo "Aborted, nothing changed."
            return
        fi
        rm -rf "$dir"
    fi

        mkdir -p "$dir/Helpers" "$dir/reports"
    cp templates/attendance_checker.py "$dir/"
    cp templates/config.json "$dir/Helpers/"
    if ! make_roster; then
        rm -rf "$dir"
        echo "Roster failed, removed $dir"
        return
    fi
    echo "Created $dir"

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
