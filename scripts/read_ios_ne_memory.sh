#!/bin/sh
# Reads the iPhone extension's memory over the tailnet via the Mac daemon.
ID=019786c8-c6b7-73ba-9e0a-8af924a4d01f   # the 16e (tailnet name iphone-xs-max)
curl -s -m 60 --unix-socket /var/run/cylonix/cylonixd.sock \
  "http://local-tailscaled.sock/localapi/v0/peer-debug/pprof?peer=$ID&name=footprint" | python3 -c '
import json,sys
j=json.load(sys.stdin); mb=lambda k: j.get(k,0)/1048576
print("footprint=%.1fMB peak=%.1fMB resident=%.1fMB goHeapInuse=%.1fMB gc=%d" % (mb("footprint"),mb("footprint_peak"),mb("resident"),mb("go_heap_inuse"),j.get("num_gc",0)))'
