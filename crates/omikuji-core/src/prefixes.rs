use crate::launch::prefix_path_for;
use crate::library::Library;
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

pub struct PrefixInfo {
    pub path: PathBuf,
    pub name: String,
    pub games: Vec<String>,
    pub runner: String,
}

struct Acc {
    display: PathBuf,
    games: Vec<String>,
    runner: String,
}

fn canonical(p: &Path) -> PathBuf {
    std::fs::canonicalize(p).unwrap_or_else(|_| p.to_path_buf())
}

pub fn list_prefixes() -> Vec<PrefixInfo> {
    let games = Library::load().map(|l| l.game).unwrap_or_default();
    let mut acc: BTreeMap<PathBuf, Acc> = BTreeMap::new();

    if let Ok(entries) = std::fs::read_dir(crate::prefixes_dir()) {
        for entry in entries.flatten() {
            let path = entry.path();
            if !path.is_dir() {
                continue;
            }
            acc.entry(canonical(&path)).or_insert_with(|| Acc {
                display: path,
                games: Vec::new(),
                runner: String::new(),
            });
        }
    }

    for game in &games {
        if !game.uses_wine_prefix() {
            continue;
        }
        let raw = prefix_path_for(game);
        if !raw.is_dir() {
            continue;
        }
        let entry = acc.entry(canonical(&raw)).or_insert_with(|| Acc {
            display: raw,
            games: Vec::new(),
            runner: String::new(),
        });
        entry.games.push(game.metadata.name.clone());
        if entry.runner.is_empty() && !game.wine.version.is_empty() {
            entry.runner = game.wine.version.clone();
        }
    }

    let default_runner = crate::defaults::Defaults::load()
        .wine
        .version
        .unwrap_or_default();

    acc.into_values()
        .map(|a| {
            let name = a
                .display
                .file_name()
                .map(|s| s.to_string_lossy().into_owned())
                .unwrap_or_else(|| a.display.to_string_lossy().into_owned());
            let runner = if a.runner.is_empty() {
                default_runner.clone()
            } else {
                a.runner
            };
            PrefixInfo {
                path: a.display,
                name,
                games: a.games,
                runner,
            }
        })
        .collect()
}

fn preset_verbs(preset: &str) -> Vec<String> {
    let verbs: &[&str] = match preset {
        "game" => &["d3dx9", "d3dcompiler_43", "d3dcompiler_47", "corefonts", "msls31"],
        _ => &["corefonts"],
    };
    verbs.iter().map(|s| s.to_string()).collect()
}

pub fn create_prefix<F: FnMut(&str)>(
    name: &str,
    runner: &str,
    preset: &str,
    on_line: F,
) -> anyhow::Result<()> {
    let folder = crate::media::slugify(name);
    if folder.is_empty() {
        anyhow::bail!("prefix name is empty");
    }
    let dir = crate::prefixes_dir().join(&folder);
    std::fs::create_dir_all(&dir)?;

    let game = crate::library::Game::with_options(
        "Ofuda".to_string(),
        PathBuf::new(),
        Some(dir.to_string_lossy().into_owned()),
        Some("wine".to_string()),
        (!runner.is_empty()).then(|| runner.to_string()),
    );

    let tool = crate::wine_tools::WineTool::WinetricksVerbs(preset_verbs(preset));
    crate::wine_tools::run_streamed(&game, tool, on_line)
}

pub fn prefix_needs_bootstrap(game: &crate::library::Game) -> bool {
    if !game.uses_wine_prefix() {
        return false;
    }
    let prefix = prefix_path_for(game);
    !prefix.join("drive_c").join("windows").join("system32").is_dir()
}

pub fn bootstrap_prefix<F: FnMut(&str)>(
    game: &crate::library::Game,
    mut on_line: F,
) -> anyhow::Result<()> {
    let variant = crate::launch::WineVariant::from_version(&game.wine.version);
    let wine_exe = crate::launch::resolve_wine_exe(variant, &game.wine.version)?;
    let env = crate::launch::build_env(game, variant, &wine_exe);
    let prefix = crate::launch::resolve_prefix(game);

    if prefix.join("drive_c").join("windows").join("system32").is_dir() {
        return Ok(());
    }

    let mut cmd = std::process::Command::new(&wine_exe);
    cmd.arg("wineboot").arg("-u");
    cmd.env_clear();
    cmd.envs(&env);
    if variant == crate::launch::WineVariant::Proton {
        cmd.env("PROTON_VERB", "waitforexitandrun");
    }
    cmd.stdin(std::process::Stdio::null());
    cmd.stdout(std::process::Stdio::null());
    cmd.stderr(std::process::Stdio::piped());

    let mut child = cmd.spawn()?;
    if let Some(stderr) = child.stderr.take() {
        use std::io::BufRead;
        for line in std::io::BufReader::new(stderr).lines().map_while(Result::ok) {
            on_line(&line);
        }
    }
    let status = child.wait()?;
    if !status.success() {
        anyhow::bail!("wineboot -u exited with {}", status);
    }
    Ok(())
}

pub fn delete_prefix(target: &Path) -> bool {
    if !target.is_dir() {
        tracing::warn!("delete_prefix: not a directory: {}", target.display());
        return false;
    }
    if !list_prefixes().iter().any(|p| p.path == target) {
        tracing::warn!("delete_prefix refused, not a known prefix: {}", target.display());
        return false;
    }
    match std::fs::remove_dir_all(target) {
        Ok(_) => true,
        Err(e) => {
            tracing::error!("delete_prefix failed: {e}");
            false
        }
    }
}
