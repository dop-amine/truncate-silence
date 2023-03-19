#!/bin/bash

# prompt the user to select the directory where the MKV files are located
echo "Please select the directory where the MKV files are located:"
read -r input_dir

# loop through all MKV files in the input directory
for input_file in "$input_dir"/*.mkv; do
    # detect the silent sections
    silence_log=$(mktemp)
    ffmpeg -i "$input_file" -af "silencedetect=n=-50dB:d=1" -c:v copy -c:a copy -strict -2 -f null - 2> "$silence_log"

    # parse the log to get the start and end times of the non-silent sections
    start_time=$(grep -E "silence_start" "$silence_log" | tail -n 1 | awk -F "silence_start: " '{print $2}')
    end_time=$(grep -E "silence_end" "$silence_log" | tail -n 1 | awk -F "silence_end: " '{print $2}')

    # trim the video in place
    ffmpeg -i "$input_file" -ss "$start_time" -to "$end_time" -c:v copy -c:a copy -y "$input_file"

    # remove the temporary log file
    rm "$silence_log"
done

echo "Done!"
