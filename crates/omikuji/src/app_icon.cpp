// this part was made with gemini btw. Couldnt bother
#include <QtCore/QString>
#include <QtGui/QGuiApplication>
#include <QtGui/QIcon>

extern "C" void omikuji_set_window_icon(const char* path) {
    if (!path) return;
    QGuiApplication::setWindowIcon(QIcon(QString::fromUtf8(path)));
}

extern "C" void omikuji_set_desktop_file_name(const char* name) {
    if (!name) return;
    QGuiApplication::setDesktopFileName(QString::fromUtf8(name));
}