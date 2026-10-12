# Deploy_agent_yshamis44

A shell script that deploys the Student Attendance Tracker, runs it, archives its logs, and cleans up if I interrupt a deployment.

## What is in the repo

deploy_agent.sh is the script. The templates folder holds the three original files from the assignment (attendance_checker.py, assets.csv, config.json), and .gitignore keeps test projects and zip files out of the repo.

## Requirements

bash, python3 and zip. The script checks python3 and zip every time it starts and stops with a message if one is missing. It also prints the python3 version.

## How to run the script

Open a terminal in the repo folder (the script reads templates/ from where you are), then run:

```
chmod +x deploy_agent.sh
./deploy_agent.sh
```

## How to choose a feature

I used a menu instead of flags:

```
1) Deploy a new project
2) Run an existing project
3) Archive logs
4) Quit
```

Type the number and press Enter. Options 2 and 3 ask for the project name, which is whatever comes after attendance_tracker_. If that folder doesn't exist, the script says so and stops.

## Deploying a project

Option 1 asks for a project name and builds this:

```
attendance_tracker_<name>/
    attendance_checker.py
    Helpers/
        config.json
        assets.csv
    reports/
```

The steps, in order:

1. Ask for the name. An empty name is rejected.
2. If the folder already exists, ask whether to overwrite. Only `y` goes ahead, anything else aborts and leaves the old project alone.
3. Copy attendance_checker.py and config.json from templates/ without changing them.
4. Ask how to build the roster (assets.csv), then how many students.
5. Set permissions: `chmod +x` on attendance_checker.py and `chmod 600` on config.json, then print both with `ls -l`.
6. Offer the threshold update.
7. Start the app. If it starts, the structure, roster and config work together.

For the roster, option 1 copies the header plus the first N rows of templates/assets.csv (the template has 10 students, so asking for more is refused). Option 2 generates N rows from a list of 10 names in the script, with both counts at 0. The count must be a whole number of at least 1. If this step fails, the half-built project is deleted.

The app works out percentages from `total_sessions`, which counts today's session, so it has to be one more than the sessions already in the roster. The template students each have 4 on record, so copy mode leaves it at 5. A generated roster starts from zero, so the script changes it to 1 with `sed`. There is no prompt for it.

## How the threshold update works

After the permissions the script asks `Update alert thresholds? (y/n)`. Anything other than `y` skips it.

If I answer `y`, it asks for the warning (default 75) and the failure (default 50). Pressing Enter keeps the default. Before it touches the file it checks that both are digits only, no longer than 3 characters, that warning is not above 100, and that failure is lower than warning. Leading zeros are removed, so `007` is written as `7`, because `007` isn't valid JSON.

If a check fails it prints why, leaves config.json alone and carries on with the deployment. If everything passes, `sed` changes only the `"warning":` and `"failure":` lines and nothing else in the file. I used `sed -i.bak` and delete the .bak straight after, because that form works on both macOS and Ubuntu.

## How the log archiving works

Option 3 asks for the project name, takes one timestamp with `date +%Y%m%d_%H%M%S`, and copies each log into its own folder:

```
attendance_tracker_<name>/archives/
    attendance/attendance_20261012_143022.log
    absent/absent_20261012_143022.log
```

Both logs from one run share a timestamp so they are easy to match, and a later run gets new names so nothing is overwritten. The script prints where each file went. absent.log only exists if someone was marked absent, so if a log is missing it prints `No absent.log to archive, skipping.` and carries on. I used `cp`, so the originals stay in reports/.

## Ctrl+C and Ctrl+Z during a deploy

While a project is being built the script traps Ctrl+C (SIGINT) and Ctrl+Z (SIGTSTP). When one arrives it prints `Deployment interrupted.`, zips whatever exists into attendance_tracker_<name>_archive.zip (in the folder I ran the script from), deletes the incomplete project folder, and exits.

If nothing has been created yet, for example Ctrl+C at the name prompt or at the overwrite question, it just says so and touches nothing. I added that check so that pressing Ctrl+C at the overwrite question can't zip and delete a project that was already there. The trap is turned off before the marking session, so it doesn't get in the way of the Python app.

To test it:

```
./deploy_agent.sh
```

Pick 1, enter a name like demo, choose a roster option, then press Ctrl+C (or Ctrl+Z) at `How many students?`. Then run:

```
ls
unzip -l attendance_tracker_demo_archive.zip
```

The zip is there and the attendance_tracker_demo folder is gone.

What is inside the zip depends on when I interrupt. At `How many students?` it holds attendance_checker.py, Helpers/config.json and an empty reports/, with no assets.csv yet. If I interrupt later, for example at the threshold question, Helpers/assets.csv is in there too.

## How I tested it

- After each deploy I ran `ls -R attendance_tracker_<name>` and checked the layout above.
- I used `cat` on assets.csv and config.json for both roster options. Copy mode keeps the 4-session counts and `total_sessions` 5. Generate mode ends every row in `0,0` and `total_sessions` is 1.
- I checked `ls -l` for the executable Python file and `-rw-------` on config.json, including after a threshold update.
- I tried bad input: a count of `abc`, an empty project name, a count above 10, `abc` and 60/70 as thresholds, and a project name that already exists.
- I ran a marking session with some students absent, checked both logs appeared in reports/, then archived them.
- I interrupted a deploy with Ctrl+C and Ctrl+Z and checked the zip and the missing folder.
- I ran it on macOS and on the Ubuntu 20.04 sandbox.

[![Watch the video](https://loom.com)](https://www.loom.com/share/8faa0a4e70354d219e379044c0fb2fff)
