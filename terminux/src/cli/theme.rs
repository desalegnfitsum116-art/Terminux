use anyhow::Context;
use clap::Parser;
use std::io::{BufRead, Write};
use std::path::PathBuf;

fn home_dir() -> PathBuf {
    if let Ok(val) = std::env::var("HOME") {
        PathBuf::from(val)
    } else {
        PathBuf::from("/tmp")
    }
}

fn xdg_config_home() -> PathBuf {
    if let Ok(val) = std::env::var("XDG_CONFIG_HOME") {
        PathBuf::from(val).join("terminux")
    } else {
        home_dir().join(".config").join("terminux")
    }
}

fn config_dir() -> PathBuf {
    if let Ok(val) = std::env::var("TERMINUX_CONFIG_DIR") {
        return PathBuf::from(val);
    }
    xdg_config_home()
}

fn theme_search_dirs() -> Vec<PathBuf> {
    let mut dirs: Vec<PathBuf> = Vec::new();
    let config = config_dir();
    dirs.push(config.join("themes"));
    dirs.push(home_dir().join(".terminux").join("themes"));
    if let Ok(exe) = std::env::current_exe() {
        if let Some(exe_dir) = exe.parent() {
            let dev_path = exe_dir.join("../../terminux/themes");
            dirs.push(dev_path);
            let install_path = exe_dir.join("terminux/themes");
            dirs.push(install_path);
        }
    }
    if let Ok(data_dir) = std::env::var("XDG_DATA_HOME") {
        dirs.push(PathBuf::from(data_dir).join("terminux").join("themes"));
    }
    dirs.retain(|d| d.exists());
    dirs
}

fn list_themes() -> Vec<String> {
    let mut themes = Vec::new();
    let mut seen = std::collections::HashSet::new();
    for dir in theme_search_dirs() {
        if let Ok(entries) = std::fs::read_dir(&dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.extension().and_then(|s| s.to_str()) == Some("lua") {
                    if let Some(stem) = path.file_stem().and_then(|s| s.to_str()) {
                        if seen.insert(stem.to_string()) {
                            themes.push(stem.to_string());
                        }
                    }
                }
            }
        }
    }
    themes.sort();
    themes
}

fn read_current_theme() -> Option<String> {
    let settings_path = config_dir().join("settings.lua");
    let file = std::fs::File::open(&settings_path).ok()?;
    let reader = std::io::BufReader::new(file);
    for line in reader.lines().flatten() {
        let trimmed = line.trim();
        if let Some(captured) = trimmed.strip_prefix("theme") {
            if let Some(eq_pos) = captured.find('=') {
                let after_eq = captured[eq_pos + 1..].trim();
                if after_eq.starts_with('"') {
                    let end = after_eq[1..].find('"')?;
                    return Some(after_eq[1..end + 1].to_string());
                }
            }
        }
    }
    None
}

fn write_theme_setting(name: &str) -> anyhow::Result<()> {
    let settings_path = config_dir().join("settings.lua");
    let content = if settings_path.exists() {
        let file = std::fs::File::open(&settings_path)?;
        let reader = std::io::BufReader::new(file);
        let mut lines: Vec<String> = reader.lines().flatten().collect();
        let mut found = false;
        for line in lines.iter_mut() {
            let trimmed = line.trim();
            if trimmed.starts_with("theme") && trimmed.contains('=') {
                *line = format!("theme = \"{}\"", name);
                found = true;
                break;
            }
        }
        if !found {
            lines.push(String::new());
            lines.push(format!("theme = \"{}\"", name));
        }
        lines.join("\n") + "\n"
    } else {
        format!("-- Terminux Settings\n\n-- Selected theme\ntheme = \"{}\"\n", name)
    };
    if let Some(parent) = settings_path.parent() {
        std::fs::create_dir_all(parent)
            .with_context(|| format!("creating {}", parent.display()))?;
    }
    let mut file = std::fs::File::create(&settings_path)
        .with_context(|| format!("writing {}", settings_path.display()))?;
    file.write_all(content.as_bytes())?;
    Ok(())
}

#[derive(Debug, Parser, Clone)]
pub struct ThemeCommand {
    #[command(subcommand)]
    sub: ThemeSubCommand,
}

#[derive(Debug, Parser, Clone)]
enum ThemeSubCommand {
    #[command(name = "list", about = "List available themes")]
    List,
    #[command(
        name = "set",
        about = "Set the active theme"
    )]
    Set {
        name: String,
    },
    #[command(name = "show", about = "Show the currently active theme")]
    Show,
}

impl ThemeCommand {
    pub fn run(&self) -> anyhow::Result<()> {
        match &self.sub {
            ThemeSubCommand::List => {
                let themes = list_themes();
                if themes.is_empty() {
                    println!("No themes found.");
                    println!();
                    println!("Theme search directories:");
                    for dir in theme_search_dirs() {
                        println!("  {}", dir.display());
                    }
                    return Ok(());
                }
                let current = read_current_theme();
                println!("Available themes:");
                for theme in &themes {
                    let marker = if Some(theme.as_str()) == current.as_deref() {
                        " *"
                    } else {
                        "  "
                    };
                    println!("  {}{}", marker, theme);
                }
                if let Some(ref cur) = current {
                    if !themes.contains(cur) {
                        println!("\nCurrent theme '{}' not found in search paths.", cur);
                    }
                }
            }
            ThemeSubCommand::Set { name } => {
                let themes = list_themes();
                if !themes.contains(name) {
                    anyhow::bail!(
                        "Theme '{}' not found. Use 'terminux theme list' to see available themes.",
                        name
                    );
                }
                write_theme_setting(name)?;
                println!("Theme set to '{}'. Reload config (default: Ctrl+Shift+R) to apply.", name);
            }
            ThemeSubCommand::Show => {
                match read_current_theme() {
                    Some(name) => println!("Current theme: {}", name),
                    None => println!("Current theme: terminux-dark (default)"),
                }
            }
        }
        Ok(())
    }
}
