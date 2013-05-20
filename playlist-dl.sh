#!/bin/bash

# Script to download Youtube playlists and convert the audio to mp3 files
#
# @author Dani Huertas
# @email huertas.dani@gmail.com
#
# Note: this script uses the following commands
# · curl
# · grep
# · awk
# · sed
# · youtube-dl - http://rg3.github.io/youtube-dl/
# · ffmpeg - http://www.ffmpeg.org/

if [ $# -eq 0 ] ; then
	echo "Usage: ./playlist.sh playlist_id"
	exit
fi

PL_ID=$1

PL_URL="http://www.youtube.com/playlist?list=$PL_ID"

MORE=true

PAGE=1

DELIM="&amp;index="

while $MORE; do

	curl "$PL_URL&page=$PAGE" --output curl.out --silent

	COUNT=`grep -c "$DELIM" curl.out`

	if [ $COUNT -gt 0 ]
	then
		cat curl.out | grep "$DELIM" | awk -F \" '{print $2, $4}' >> playlist.out
		
		echo "page: $PAGE, count: $COUNT"
		PAGE=`expr $PAGE + 1`
	else
		echo "playlist fetched!"
		MORE=false
	fi

done

cat playlist.out | while read line; do

	URL="http://www.youtube.com$(echo $line | awk '{print $1}')"
	IN=`youtube-dl --get-filename -o "%(title)s.%(ext)s" "$URL"`

	echo $IN

	OUT=`echo "$IN" |sed 's/mp4/mp3/'`

	# Download video file
	youtube-dl -o "%(title)s.%(ext)s" "$URL" >log_youtube-dl.log

	# Convert video file to mp3 audio
	ffmpeg -i "$IN" -f mp3 -ab 256000 -vn "$OUT" -v quiet >log_ffmpeg.log &

done

# Clean folder
rm *.mp4
rm curl.out
rm playlist.out