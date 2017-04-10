#!/bin/bash
find /music/ -xdev -type f -not -name '*.mp3' -and -not -name '*.m4a' -and -not -name '*.wav' -and -not -name '*.flac' -print0 | xargs -0 rm -v
