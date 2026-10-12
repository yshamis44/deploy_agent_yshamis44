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
update_thresholds() {
    read -r -p "Update alert thresholds? (y/n) " ans
    if [ "$ans" != "y" ]; then
        return
    fi

    read -r -p "Warning threshold [75]: " warn
    read -r -p "Failure threshold [50]: " fail
    warn=${warn:-75}
    fail=${fail:-50}

    for v in "$warn" "$fail"; do
        case "$v" in
            *[!0-9]*|????*) echo "'$v' is not a valid number, thresholds unchanged."; return ;;
        esac
    done

    warn=$((10#$warn))
    fail=$((10#$fail))
    if [ "$warn" -gt 100 ] || [ "$fail" -ge "$warn" ]; then
        echo "Failure must be lower than warning, and warning at most 100. Thresholds unchanged."
        return
    fi

    cfg="$dir/Helpers/config.json"
    sed -i.bak "s/\"warning\": [0-9]*/\"warning\": $warn/" "$cfg"
    sed -i.bak "s/\"failure\": [0-9]*/\"failure\": $fail/" "$cfg"
    rm "$cfg.bak"
    echo "Thresholds set: warning=$warn failure=$fail"
}
pick_project() {
    read -r -p "Project name: " name
    dir="attendance_tracker_$name"
    if [ ! -d "$dir" ]; then
        echo "$dir not found."
        return 1
    fi
}

start_app() {
    (cd "$dir" && python3 attendance_checker.py)
}

interrupted() {
    echo
    echo "Deployment interrupted."
    if [ "$made" = "yes" ] && [ -d "$dir" ]; then
        zip -rq "${dir}_archive.zip" "$dir"
        rm -rf "$dir"
        echo "Saved what was built to ${dir}_archive.zip and removed $dir"
    else
        echo "Nothing had been created yet."
    fi
    exit 1
}

deploy() {
    made=""
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
        made="yes"
    cp templates/attendance_checker.py "$dir/"
    cp templates/config.json "$dir/Helpers/"
    if ! make_roster; then
        rm -rf "$dir"
        echo "Roster failed, removed $dir"
        return
    fi    
    chmod +x "$dir/attendance_checker.py"
    chmod 600 "$dir/Helpers/config.json"
    echo "Permissions set:"
    ls -l "$dir/attendance_checker.py" "$dir/Helpers/config.json"
    
    update_thresholds
    trap - INT TSTP
    start_app
    echo "Created $dir"

}

run_app() {
    pick_project && start_app
}

archive_logs() {
    pick_project || return
    ts=$(date +%Y%m%d_%H%M%S)
    mkdir -p "$dir/archives/attendance" "$dir/archives/absent"

    for kind in attendance absent; do
        log="$dir/reports/$kind.log"
        if [ -f "$log" ]; then
            cp "$log" "$dir/archives/$kind/${kind}_$ts.log"
            echo "Archived $log -> $dir/archives/$kind/${kind}_$ts.log"
        else
            echo "No $kind.log to archive, skipping."
        fi
    done
}

check_tools

echo "1) Deploy a new project"
echo "2) Run an existing project"
echo "3) Archive logs"
echo "4) Quit"
read -r -p "Pick one: " choice

case "$choice" in
    1) trap interrupted INT TSTP
       deploy
       trap - INT TSTP ;;
    2) run_app ;;
    3) archive_logs ;;
    4) exit 0 ;;
    *) echo "Invalid choice" ;;
esac
