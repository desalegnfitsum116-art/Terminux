# Terminux Crash Recovery

## How It Works

Terminux detects unclean shutdowns using a health marker file:

1. **On startup**: a `.healthy` marker is written to `~/.config/terminux/sessions/`
2. **On clean shutdown**: the marker is deleted and `last-session.json` is written
3. **On next startup**: if the marker still exists, Terminux knows the previous session crashed

## Recovery Flow

When a crash is detected:

1. Terminux shows a non-blocking notification: *"Terminux recovered from a crash"*
2. The `recovery.log` is updated with the timestamp
3. The autosave file is preserved
4. You can restore from the last autosave via **Session: Restore Last Session** in the command palette

## Recovery Options

### Option 1: Restore from Autosave (Recommended)

1. Open the command palette (CTRL+SHIFT+P)
2. Select **Session: Restore Last Session**
3. This restores tabs, panes, working directories, and theme

### Option 2: Restore from CLI

```bash
terminux session restore                 # Restore last session
terminux session restore <name>          # Restore a named session
terminux session list                    # See available sessions
```

After running a CLI restore, reload with `terminux reload` or CTRL+SHIFT+R.

### Option 3: Restore from Backup

If autosave.json is corrupted, the previous version is at:

```
~/.config/terminux/sessions/autosave.json.bak
```

```bash
cp ~/.config/terminux/sessions/autosave.json.bak ~/.config/terminux/sessions/autosave.json
terminux reload
```

### Option 4: Start Fresh

If you don't want to restore:

```bash
rm ~/.config/terminux/sessions/autosave.json
rm ~/.config/terminux/sessions/autosave.json.bak
terminux reload
```

## Recovery Log

All recovery events are logged to:

```
~/.config/terminux/recovery.log
```

View it:

```bash
cat ~/.config/terminux/recovery.log
```

Clear it:

```bash
> ~/.config/terminux/recovery.log
```

## Preventing Data Loss

Autosave writes every **30 seconds** using atomic file operations:

1. Content is written to `autosave.json.tmp.<random>`
2. The temp file is renamed atomically to `autosave.json`
3. The previous autosave is backed up to `autosave.json.bak`

This prevents corruption from mid-write crashes.

## What's NOT Recovered

- **Scrollback buffer**: terminal history is not saved
- **Environment variables**: only `cwd` is preserved
- **SSH sessions**: reconnection is manual (no passwords/keys stored)
- **Pane zoom state**: flat pane list is restored
- **Exact pixel positions**: proportional layout is used

## SSH Sessions After Crash

SSH sessions are stored as metadata (host, user, port). On restore:

1. A notification shows: *"SSH session saved: user@host:port - reconnect manually"*
2. Reconnect via the command palette or `terminux ssh user@host`
3. Use agent-based authentication for passwordless reconnection

## Corrupted Session File Handling

If a session file can't be parsed:

1. The error is logged
2. A notification is shown
3. The file is left in place for inspection
4. Terminux starts with a clean session

To inspect a corrupted file:

```bash
python3 -m json.tool ~/.config/terminux/sessions/autosave.json
```
