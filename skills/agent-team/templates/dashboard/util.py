#!/usr/bin/env python3
"""Tiny CLI for multi-agent dashboard updates.

Usage:
  util.py log <agent> <model> "<msg>"
  util.py status <agent> <status> [activity...]   # status: idle|running|done|error
  util.py phase <num> "<label>"
"""
import json, sys, os, datetime

DIR = os.path.dirname(os.path.abspath(__file__))
STATUS = os.path.join(DIR, "status.json")
LOG = os.path.join(DIR, "log.jsonl")

def now_iso():
    return datetime.datetime.now().isoformat(timespec="seconds")

def cmd_log(agent, model, msg):
    entry = {"ts": now_iso(), "agent": agent, "model": model, "msg": msg}
    with open(LOG, "a") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")

def load_status():
    with open(STATUS) as f: return json.load(f)
def save_status(s):
    tmp = STATUS + ".tmp"
    with open(tmp, "w") as f: json.dump(s, f, ensure_ascii=False, indent=2)
    os.replace(tmp, STATUS)

def cmd_status(agent, status, activity=""):
    s = load_status()
    if agent not in s["agents"]:
        # Allow on-the-fly registration so unconfigured agents still show up
        s["agents"][agent] = {"name": agent, "model": "", "role": "", "status": "idle",
                              "activity": "", "startedAt": None, "endedAt": None}
    a = s["agents"][agent]
    a["status"] = status
    if activity: a["activity"] = activity
    if status == "running" and not a.get("startedAt"):
        a["startedAt"] = now_iso(); a["endedAt"] = None
    if status in ("done", "error"):
        a["endedAt"] = now_iso()
    save_status(s)
    cmd_log(agent, a.get("model",""), f"[{status}] {activity}".strip())

def cmd_phase(num, label):
    s = load_status()
    s["phase"] = int(num); s["phaseLabel"] = label
    save_status(s)
    cmd_log("system", "", f"PHASE {num}: {label}")

def main():
    if len(sys.argv) < 2: print(__doc__); sys.exit(1)
    op = sys.argv[1]
    if op == "log":      cmd_log(sys.argv[2], sys.argv[3], sys.argv[4])
    elif op == "status": cmd_status(sys.argv[2], sys.argv[3], " ".join(sys.argv[4:]))
    elif op == "phase":  cmd_phase(sys.argv[2], sys.argv[3])
    else: print(__doc__); sys.exit(1)

if __name__ == "__main__":
    main()
