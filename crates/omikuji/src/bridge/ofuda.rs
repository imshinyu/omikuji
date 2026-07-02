use std::pin::Pin;

use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;
use omikuji_core::fs_watcher::DirWatcher;
use omikuji_core::prefixes as core_prefixes;

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        #[qproperty(bool, creating)]
        type OfudaBridge = super::OfudaRust;
    }

    unsafe extern "RustQt" {
        #[qsignal]
        fn changed(self: Pin<&mut OfudaBridge>);

        #[qsignal]
        #[cxx_name = "createFinished"]
        fn create_finished(self: Pin<&mut OfudaBridge>, ok: bool, error: QString);

        #[qsignal]
        #[cxx_name = "createOutput"]
        fn create_output(self: Pin<&mut OfudaBridge>, line: QString);

        #[qinvokable]
        #[cxx_name = "listJson"]
        fn list_json(self: &OfudaBridge) -> QString;

        #[qinvokable]
        #[cxx_name = "runTool"]
        fn run_tool(self: &OfudaBridge, path: &QString, tool: &QString, runner: &QString) -> bool;

        #[qinvokable]
        #[cxx_name = "openFolder"]
        fn open_folder(self: &OfudaBridge, path: &QString) -> bool;

        #[qinvokable]
        #[cxx_name = "deletePrefix"]
        fn delete_prefix(self: Pin<&mut OfudaBridge>, path: &QString) -> bool;

        #[qinvokable]
        #[cxx_name = "createPrefix"]
        fn create_prefix(
            self: Pin<&mut OfudaBridge>,
            name: &QString,
            runner: &QString,
            preset: &QString,
        );

        #[qinvokable]
        fn watch(self: Pin<&mut OfudaBridge>);
    }

    impl cxx_qt::Threading for OfudaBridge {}
}

#[derive(Default)]
pub struct OfudaRust {
    watcher: Option<DirWatcher>,
    creating: bool,
}

impl qobject::OfudaBridge {
    fn list_json(&self) -> QString {
        let list: Vec<serde_json::Value> = core_prefixes::list_prefixes()
            .into_iter()
            .map(|p| {
                serde_json::json!({
                    "path": p.path.to_string_lossy(),
                    "name": p.name,
                    "gameCount": p.games.len(),
                    "games": p.games,
                    "runner": p.runner,
                })
            })
            .collect();
        QString::from(&serde_json::Value::Array(list).to_string())
    }

    fn run_tool(&self, path: &QString, tool: &QString, runner: &QString) -> bool {
        use omikuji_core::wine_tools::WineTool;
        let tool = match tool.to_string().as_str() {
            "winecfg" => WineTool::Winecfg,
            "winetricks" => WineTool::Winetricks,
            "kill" => WineTool::KillWineserver,
            other => {
                tracing::warn!("unknown ofuda tool: {other}");
                return false;
            }
        };
        let prefix = path.to_string();
        let runner = runner.to_string();
        let game = omikuji_core::library::Game::with_options(
            "Ofuda".to_string(),
            std::path::PathBuf::new(),
            (!prefix.is_empty()).then_some(prefix),
            Some("wine".to_string()),
            (!runner.is_empty()).then_some(runner),
        );
        match omikuji_core::wine_tools::run(&game, tool) {
            Ok(_) => true,
            Err(e) => {
                tracing::error!("ofuda run_tool failed: {e}");
                false
            }
        }
    }

    fn open_folder(&self, path: &QString) -> bool {
        match omikuji_core::desktop::browse_files(std::path::Path::new(&path.to_string())) {
            Ok(_) => true,
            Err(e) => {
                tracing::error!("ofuda open_folder failed: {e}");
                false
            }
        }
    }

    fn delete_prefix(mut self: Pin<&mut Self>, path: &QString) -> bool {
        let ok = core_prefixes::delete_prefix(std::path::Path::new(&path.to_string()));
        if ok {
            self.as_mut().changed();
        }
        ok
    }

    fn create_prefix(
        mut self: Pin<&mut Self>,
        name: &QString,
        runner: &QString,
        preset: &QString,
    ) {
        if self.creating {
            return;
        }
        self.as_mut().set_creating(true);
        let qt = self.as_mut().qt_thread();
        let name = name.to_string();
        let runner = runner.to_string();
        let preset = preset.to_string();
        std::thread::spawn(move || {
            let line_qt = qt.clone();
            let res = core_prefixes::create_prefix(&name, &runner, &preset, |line| {
                let l = line.to_string();
                let _ = line_qt.queue(move |mut obj: Pin<&mut qobject::OfudaBridge>| {
                    obj.as_mut().create_output(QString::from(&l));
                });
            });
            let (ok, err) = match res {
                Ok(_) => (true, String::new()),
                Err(e) => (false, e.to_string()),
            };
            let _ = qt.queue(move |mut obj: Pin<&mut qobject::OfudaBridge>| {
                obj.as_mut().set_creating(false);
                obj.as_mut().create_finished(ok, QString::from(&err));
                obj.as_mut().changed();
            });
        });
    }

    fn watch(mut self: Pin<&mut Self>) {
        if self.watcher.is_some() {
            return;
        }
        let qt_thread = self.as_mut().qt_thread();
        let watcher = DirWatcher::watch(
            omikuji_core::prefixes_dir(),
            |_| true,
            move || {
                let _ = qt_thread.queue(move |mut obj: Pin<&mut qobject::OfudaBridge>| {
                    obj.as_mut().changed();
                });
            },
        );
        match watcher {
            Ok(w) => self.as_mut().rust_mut().get_mut().watcher = Some(w),
            Err(e) => tracing::error!("failed to watch prefixes dir: {e}"),
        }
    }
}
