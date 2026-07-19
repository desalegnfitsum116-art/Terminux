use anyhow::Context;
use clap::Parser;
use std::io::Write;
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

fn plugin_dir() -> PathBuf {
    config_dir().join("plugins")
}

fn disabled_file() -> PathBuf {
    config_dir().join("disabled_plugins.lua")
}

fn list_plugins() -> Vec<String> {
    let mut plugins = Vec::new();
    let dir = plugin_dir();
    if let Ok(entries) = std::fs::read_dir(&dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.is_dir() {
                if let Some(name) = path.file_name().and_then(|s| s.to_str()) {
                    if !name.starts_with('.') {
                        plugins.push(name.to_string());
                    }
                }
            }
        }
    }
    plugins.sort();
    plugins
}

fn read_disabled() -> Vec<String> {
    let file = disabled_file();
    let content = match std::fs::read_to_string(&file) {
        Ok(c) => c,
        Err(_) => return vec![],
    };
    let mut disabled = Vec::new();
    for line in content.lines() {
        let trimmed = line.trim();
        if let Some(name) = trimmed.strip_prefix('"') {
            if let Some(end) = name.find('"') {
                disabled.push(name[..end].to_string());
            }
        }
    }
    disabled
}

fn write_disabled(disabled: &[String]) -> anyhow::Result<()> {
    let mut content = "-- Terminux Disabled Plugins\n\nreturn {\n".to_string();
    for name in disabled {
        content.push_str(&format!("  \"{}\",\n", name));
    }
    content.push_str("}\n");
    let file = disabled_file();
    if let Some(parent) = file.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("creating {}", parent.display()))?;
    }
    let mut f = std::fs::File::create(&file)
        .with_context(|| format!("writing {}", file.display()))?;
    f.write_all(content.as_bytes())?;
    Ok(())
}

#[derive(Debug, Parser, Clone)]
pub struct PluginCommand {
    #[command(subcommand)]
    sub: PluginSubCommand,
}

#[derive(Debug, Parser, Clone)]
enum PluginSubCommand {
    #[command(name = "list", about = "List installed plugins")]
    List,
    #[command(name = "reload", about = "Reload all plugins")]
    Reload,
    #[command(name = "enable", about = "Enable a plugin")]
    Enable {
        name: String,
    },
    #[command(name = "disable", about = "Disable a plugin")]
    Disable {
        name: String,
    },
}

impl PluginCommand {
    pub fn run(&self) -> anyhow::Result<()> {
        match &self.sub {
            PluginSubCommand::List => {
                let plugins = list_plugins();
                let disabled = read_disabled();
                if plugins.is_empty() {
                    println!("No plugins found in {}", plugin_dir().display());
                    return Ok(());
                }
                println!("Installed plugins:");
                for plugin in &plugins {
                    let is_disabled = disabled.contains(plugin);
                    let status = if is_disabled {
                        " [disabled]"
                    } else {
                        " [enabled] "
                    };
                    println!("  {}{}", plugin, status);
                }
            }
            PluginSubCommand::Reload => {
                println!("Plugin reload will take effect after config reload.");
                println!("Run 'terminux reload' or press CTRL+SHIFT+R in the GUI.");
            }
            PluginSubCommand::Enable { name } => {
                let plugins = list_plugins();
                if !plugins.contains(name) {
                    anyhow::bail!("Plugin '{}' not found.", name);
                }
                let mut disabled = read_disabled();
                disabled.retain(|d| d != name);
                write_disabled(&disabled)?;
                println!("Plugin '{}' enabled. Reload config to apply.", name);
            }
            PluginSubCommand::Disable { name } => {
                let plugins = list_plugins();
                if !plugins.contains(name) {
                    anyhow::bail!("Plugin '{}' not found.", name);
                }
                let mut disabled = read_disabled();
                if !disabled.contains(name) {
                    disabled.push(name.clone());
                }
                write_disabled(&disabled)?;
                println!("Plugin '{}' disabled. Reload config to apply.", name);
            }
        }
        Ok(())
    }
}
