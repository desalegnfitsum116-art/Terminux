use anyhow::Context;
use clap::Parser;
use std::io::Read;
use std::path::PathBuf;

fn config_dir() -> PathBuf {
    if let Ok(val) = std::env::var("TERMINUX_CONFIG_DIR") {
        return PathBuf::from(val);
    }
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
    if let Ok(val) = std::env::var("XDG_CONFIG_HOME") {
        return PathBuf::from(val).join("terminux");
    }
    PathBuf::from(home).join(".config").join("terminux")
}

fn sessions_dir() -> PathBuf {
    config_dir().join("sessions")
}

fn workspaces_dir() -> PathBuf {
    sessions_dir().join("workspaces")
}

fn autosave_path() -> PathBuf {
    sessions_dir().join("autosave.json")
}

fn list_sessions() -> Vec<String> {
    let mut sessions = Vec::new();
    let dir = sessions_dir();
    if let Ok(entries) = std::fs::read_dir(&dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("json") {
                let stem = path.file_stem().and_then(|s| s.to_str());
                if stem != Some("autosave") && stem != Some("last-session") {
                    if let Some(name) = stem {
                        sessions.push(name.to_string());
                    }
                }
            }
        }
    }
    sessions.sort();
    sessions
}

fn list_workspaces() -> Vec<String> {
    let mut names = Vec::new();
    let dir = workspaces_dir();
    if let Ok(entries) = std::fs::read_dir(&dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("json") {
                if let Some(name) = path.file_stem().and_then(|s| s.to_str()) {
                    names.push(name.to_string());
                }
            }
        }
    }
    names.sort();
    names
}

fn copy_file(src: &PathBuf, dst: &PathBuf) -> anyhow::Result<()> {
    if let Some(parent) = dst.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("creating {}", parent.display()))?;
    }
    std::fs::copy(src, dst)
        .with_context(|| format!("copying {} to {}", src.display(), dst.display()))?;
    Ok(())
}

fn read_file_to_string(path: &PathBuf) -> anyhow::Result<String> {
    let mut f = std::fs::File::open(path)
        .with_context(|| format!("reading {}", path.display()))?;
    let mut content = String::new();
    f.read_to_string(&mut content)
        .with_context(|| format!("reading {}", path.display()))?;
    Ok(content)
}

#[derive(Debug, Parser, Clone)]
pub struct SessionCommand {
    #[command(subcommand)]
    sub: SessionSubCommand,
}

#[derive(Debug, Parser, Clone)]
enum SessionSubCommand {
    #[command(name = "save", about = "Save the current session to a named file")]
    Save {
        name: Option<String>,
    },
    #[command(name = "restore", about = "Restore a session")]
    Restore {
        name: Option<String>,
    },
    #[command(name = "list", about = "List saved sessions and workspaces")]
    List,
    #[command(name = "delete", about = "Delete a workspace snapshot")]
    Delete {
        name: String,
    },
    #[command(name = "export", about = "Export a session to a portable file")]
    Export {
        name: String,
        output: PathBuf,
    },
    #[command(name = "import", about = "Import a session from a portable file")]
    Import {
        input: PathBuf,
    },
}

impl SessionCommand {
    pub fn run(&self) -> anyhow::Result<()> {
        match &self.sub {
            SessionSubCommand::Save { name } => {
                let name = name.clone().unwrap_or_else(|| {
                    let ts = chrono::Local::now().format("%Y%m%d-%H%M%S");
                    format!("session-{}", ts)
                });
                let src = autosave_path();
                if !src.exists() {
                    anyhow::bail!(
                        "No autosave found at {}. Run 'Session: Save Now' from the command palette first.",
                        src.display()
                    );
                }
                let dst = sessions_dir().join(format!("{}.json", name));
                copy_file(&src, &dst)?;
                println!("Session saved as '{}'", name);
            }
            SessionSubCommand::Restore { name } => {
                let src = match name {
                    Some(n) => sessions_dir().join(format!("{}.json", n)),
                    None => sessions_dir().join("last-session.json"),
                };
                if !src.exists() {
                    anyhow::bail!(
                        "Session file not found: {}",
                        src.display()
                    );
                }
                let dst = autosave_path();
                copy_file(&src, &dst)?;
                println!(
                    "Session '{}' staged for restore. Reload config (terminux reload) or press CTRL+SHIFT+R in the GUI.",
                    name.as_deref().unwrap_or("last-session")
                );
            }
            SessionSubCommand::List => {
                let sessions = list_sessions();
                let workspaces = list_workspaces();
                println!("Sessions directory: {}", sessions_dir().display());
                println!();
                if sessions.is_empty() {
                    println!("No named sessions found.");
                } else {
                    println!("Saved sessions:");
                    for s in &sessions {
                        println!("  {}", s);
                    }
                }
                println!();
                if workspaces.is_empty() {
                    println!("No workspace snapshots found.");
                } else {
                    println!("Workspace snapshots:");
                    for w in &workspaces {
                        println!("  {}", w);
                    }
                }
            }
            SessionSubCommand::Delete { name } => {
                let path = workspaces_dir().join(format!("{}.json", name));
                if !path.exists() {
                    anyhow::bail!("Workspace '{}' not found.", name);
                }
                std::fs::remove_file(&path)
                    .with_context(|| format!("deleting {}", path.display()))?;
                println!("Workspace '{}' deleted.", name);
            }
            SessionSubCommand::Export { name, output } => {
                let src = sessions_dir().join(format!("{}.json", name));
                if !src.exists() {
                    anyhow::bail!("Session '{}' not found.", name);
                }
                copy_file(&src, output)?;
                println!("Session '{}' exported to {}", name, output.display());
            }
            SessionSubCommand::Import { input } => {
                if !input.exists() {
                    anyhow::bail!("File not found: {}", input.display());
                }
                let content = read_file_to_string(input)?;
                // Validate JSON
                let _: serde_json::Value = serde_json::from_str(&content)
                    .with_context(|| format!("invalid JSON in {}", input.display()))?;
                let dst = autosave_path();
                copy_file(input, &dst)?;
                println!(
                    "Session imported to autosave. Reload config to apply: terminux reload"
                );
            }
        }
        Ok(())
    }
}
