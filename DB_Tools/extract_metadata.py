import taglib
import sys

path = sys.argv[1]
song = taglib.File(path)
print song.tags
