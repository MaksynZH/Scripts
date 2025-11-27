problem_files=$(find /tmp/gologin_*/profiles/*/* -type f -name "chrome_debug.log"); for file in $problem_files; do echo "0" > "$file"; done;
