#!/bin/bash

for f in $@; do
	if [[ -f ${f%.mp4}.srt ]]; then
		continue
	fi
	echo $f
	ffmpeg -i $f ${f%.mp4}.mp3
	whisper-cpp -m /Users/fumire/Library/CloudStorage/Dropbox/AI/whisper-model/ggml-large-v3-turbo.bin -osrt -l ko -t 8 -p 8 -f ${f%.mp4}.mp3
	mv -v ${f%.mp4}.mp3.srt ${f%.mp4}.srt
	rm -fv ${f%.mp4}.mp3
done