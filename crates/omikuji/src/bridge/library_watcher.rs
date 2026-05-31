use std::pin::Pin;

use cxx_qt::{CxxQtType, Threading};
use cxx_qt_lib::QString;
use omikuji_core::fs_watcher::DirWatcher;

#[cxx_qt::bridge]
pub mod qobject {
    unsafe extern "C++" {
        include!("cxx-qt-lib/qstring.h");
        type QString = cxx_qt_lib::QString;
    }

    extern "RustQt" {
        #[qobject]
        #[qml_element]
        type LibraryWatcher = super::LibraryWatcherRust;
    }

    unsafe extern "RustQt" {
        #[qsignal]
        fn changed(self: Pin<&mut LibraryWatcher>);

        #[qinvokable]
        fn watch(self: Pin<&mut LibraryWatcher>, path: &QString);

        #[qinvokable]
        fn stop(self: Pin<&mut LibraryWatcher>);
    }

    impl cxx_qt::Threading for LibraryWatcher {}
}

#[derive(Default)]
pub struct LibraryWatcherRust {
    watcher: Option<DirWatcher>,
}

impl qobject::LibraryWatcher {
    fn watch(mut self: Pin<&mut Self>, path: &QString) {
        let path_str = path.to_string();
        let path_buf = std::path::PathBuf::from(&path_str);

        tracing::debug!("watching: {}", path_str);

        let qt_thread = self.as_mut().qt_thread();
        let watcher = DirWatcher::watch(
            path_buf,
            |p| {
                p.extension()
                    .and_then(|e| e.to_str())
                    .map(|e| e == "toml")
                    .unwrap_or(false)
            },
            move || {
                let _ = qt_thread.queue(move |mut obj: Pin<&mut qobject::LibraryWatcher>| {
                    obj.as_mut().changed();
                });
            },
        );

        match watcher {
            Ok(w) => self.as_mut().rust_mut().get_mut().watcher = Some(w),
            Err(e) => tracing::error!("failed to start: {e}"),
        }
    }

    fn stop(mut self: Pin<&mut Self>) {
        self.as_mut().rust_mut().get_mut().watcher = None;
    }
}
