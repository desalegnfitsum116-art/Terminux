# Terminux Session Persistence

Terminux saves and restores tabs, panes, working directories, themes, and workspace state across restarts.

---

## Session Storage Layout

```
~/.config/terminux/sessions/
├── autosave.json           # Periodic autosave (every 30s)
├── autosave.json.bak       # Previous autosave backup
├── last-session.json       # Saved on clean shutdown
├── .healthy                # Crash detection marker
└── workspaces/
    ├── webapp.json
    └── dotfiles.json
```

## Autosave

Autosave runs every **30 seconds** via `terminux.time.call_after`.

- **Asynchronous** — never blocks rendering
- **Atomic writes** — writes to a `.tmp` file, then renames atomically
- **Backup** — previous autosave is copied to `autosave.json.bak` before each write
- **Graceful degradation** — if the mux is not yet available, autosave skips silently

To manually trigger a save: **Session: Save Now** in the command palette.

## Saving a Session

### From the command palette:

1. Open the palette (CTRL+SHIFT+P)
2. Select **Session: Save Now**

### From the CLI:

```bash
terminux session save                    # Save as timestamped name
terminux session save my-session         # Save as "my-session"
```

Named sessions are stored in `~/.config/terminux/sessions/<name>.json`.

## Restoring a Session

### From the command palette:

1. Open the palette
2. Select **Session: Restore Last Session**

### From the CLI:

```bash
terminux session restore                 # Restore from last-session.json
terminux session restore my-session      # Restore a named session
```

Restore stages the session into `autosave.json` and requires a config reload (`terminux reload` or CTRL+SHIFT+R).

## What Gets Saved

| Field | Description |
|-------|-------------|
| `version` | Schema version (currently 1) |
| `created_at` | ISO 8601 timestamp |
| `terminux_version` | Terminux version string |
| `window` | Width, height, maximized state |
| `tabs[]` | Ordered list of tabs |
| `tabs[].title` | Tab title |
| `tabs[].panes[]` | Panes within the tab |
| `tabs[].panes[].cwd` | Working directory |
| `tabs[].panes[].title` | Pane title |
| `tabs[].panes[].domain` | Domain type ("unix" or "ssh://...") |
| `tabs[].panes[].process` | Foreground process path |
| `workspace.name` | Active workspace name |
| `workspace.theme` | Active theme name |
| `workspace.font_size` | Font size |
| `ssh_sessions[]` | SSH connection metadata |

## Session File Schema

```json
{
    "version": 1,
    "created_at": "2026-07-19T12:00:00Z",
    "terminux_version": "1.0.0",
    "window": {
        "width": 1600,
        "height": 900,
        "maximized": true
    },
    "tabs": [
        {
            "title": "WebApp",
            "panes": [
                { "cwd": "/home/user/Projects/webapp", "title": "vim", "domain": "unix" },
                { "cwd": "/home/user/Projects/webapp/server", "domain": "unix" }
            ]
        }
    ],
    "workspace": {
        "name": "default",
        "theme": "neon",
        "font_size": 14.0
    },
    "ssh_sessions": [
        { "host": "prod.example.com", "user": "ubuntu", "port": 22 }
    ]
}
```

## Workspace Snapshots

Named workspace snapshots capture:

- All tabs and pane layouts
- Working directories
- Active theme
- Window dimensions

### CLI

```bash
terminux session list                    # List all sessions and workspaces
terminux session delete <name>           # Delete a workspace snapshot
```

### Command Palette

| Command | Description |
|---------|-------------|
| Session: Save As Workspace | Save current layout as a named workspace |
| Session: Open Workspace | List and load a workspace snapshot |
| Session: Delete Workspace | Delete a workspace snapshot |

---

## SSH Sessions

SSH sessions are captured **safely**:

- Host, user, and port are stored
- **Passwords and private keys are never stored**
- On restore, you are prompted to reconnect manually
- Agent-based authentication is supported

Restored SSH entry:

```json
{
    "ssh": {
        "host": "prod.example.com",
        "user": "ubuntu",
        "port": 22
    }
}
```

When a session with SSH tabs is restored, a notification shows the connection details. You reconnect manually via the command palette or `terminux ssh user@host`.

---

## Export / Import

Export creates a portable `terminux-session-v1` JSON file.

```bash
terminux session export my-session ~/mysession.json
terminux session import ~/mysession.json
```

From the command palette:

| Command | Description |
|---------|-------------|
| Session: Export Session | Export current session to `~/terminux-session-<timestamp>.json` |
| Session: Import Session | Import a session from a file |

The export format includes all session data plus `export_metadata`:

```json
{
    "export_metadata": {
        "exported_at": "2026-07-19T12:00:00Z",
        "format": "terminux-session-v1"
    },
    ...
}
```

---

## Troubleshooting

### Corrupted Session File

If a session file is corrupted:

1. The validation check fails with `invalid JSON`
2. A notification is shown
3. The corrupted file is **not deleted** — inspect it at `~/.config/terminux/sessions/autosave.json`
4. The backup is at `~/.config/terminux/sessions/autosave.json.bak`

### Recovery

```bash
# Restore from backup
cp ~/.config/terminux/sessions/autosave.json.bak ~/.config/terminux/sessions/autosave.json

# View recovery log
cat ~/.config/terminux/recovery.log

# Clear recovery log
rm ~/.config/terminux/recovery.log
```

See `recovery.md` for crash recovery instructions.
