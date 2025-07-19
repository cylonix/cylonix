#include <algorithm>
#include <filesystem>
#include <flutter/dart_project.h>
#include <fstream>
#include <io.h>
#include <iostream>
#include <string>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

#include <ShellScalingApi.h>
#pragma comment(lib, "Shcore.lib")

bool enableDebugConsole = false;
std::ofstream logStream;

std::string trim(const std::string &str) {
    size_t first = str.find_first_not_of(" \t\f\v\n\r");
    if (first == std::string::npos)
        return "";
    size_t last = str.find_last_not_of(" \t\f\v\n\r");
    return str.substr(first, (last - first + 1));
}

namespace fs = std::filesystem;
void SetupLogFile() {
    wchar_t *programDataPath = nullptr;
    size_t len = 0;
    _wdupenv_s(&programDataPath, &len, L"ProgramData");
    fs::path logDir;
    if (programDataPath && wcslen(programDataPath) > 0) {
        logDir = fs::path(programDataPath) / "Cylonix" / "Logs";
    } else {
        // Fallback to a location always available to the user
        wchar_t *userProfile = nullptr;
        _wdupenv_s(&userProfile, &len, L"USERPROFILE");
        if (userProfile && wcslen(userProfile) > 0) {
            logDir = fs::path(userProfile) / "Cylonix" / "Logs";
        } else {
            // Last resort: use current directory
            logDir = fs::path(".") / "Cylonix" / "Logs";
        }
        if (userProfile)
            free(userProfile);
    }
    wchar_t *localAppData = nullptr;
    _wdupenv_s(&localAppData, &len, L"LOCALAPPDATA");
    if (localAppData && wcslen(localAppData) > 0) {
        std::wofstream fallback(std::wstring(localAppData) +
                                L"\\cylonix-log-fallback.txt");
        fallback << logDir << std::endl;
        fallback.close();
    }
    if (localAppData)
        free(localAppData);
    fs::create_directories(logDir);

    fs::path logFile = logDir / "cylonix-app-log.txt";
    fs::path rotatedLogFile = logDir / "cylonix-app-log-1.txt";

    // Rotate if log file > 64KB
    if (fs::exists(logFile) && fs::file_size(logFile) > 64 * 1024) {
        if (fs::exists(rotatedLogFile)) {
            fs::remove(rotatedLogFile);
        }
        fs::rename(logFile, rotatedLogFile);
    }

    // Open log file for appending (UTF-8)
    logStream.open(logFile, std::ios::app);
    logStream.imbue(std::locale("en_US.UTF-8"));
    if (programDataPath)
        free(programDataPath);
}

Win32Window::Point GetWindowPosition(Win32Window::Size size) {
    Win32Window::Point origin(80, 20);
    POINT cursorPos;
    if (!GetCursorPos(&cursorPos)) {
        return origin;
    }
    // Get monitor containing cursor
    HMONITOR hMonitor = MonitorFromPoint(cursorPos, MONITOR_DEFAULTTONEAREST);
    MONITORINFO monitorInfo = {sizeof(MONITORINFO)};
    if (!GetMonitorInfo(hMonitor, &monitorInfo)) {
        return origin;
    }
    // Position window near cursor but ensure it stays within
    // work area Offset by a small amount to not appear directly
    // under cursor
    const int offsetX = 20;
    const int offsetY = 20;
    float dpiScale = 1.0f;
    UINT dpiX, dpiY;
    if (GetDpiForMonitor(hMonitor, MDT_EFFECTIVE_DPI, &dpiX, &dpiY) == S_OK) {
        dpiScale = dpiX / 96.0f;
    }
    Win32Window::Size scaledSize =
        Win32Window::Size(static_cast<unsigned int>(size.width * dpiScale),
                          static_cast<unsigned int>(size.height * dpiScale));
    logStream << "Monitor work area: " << monitorInfo.rcWork.left << ", "
              << monitorInfo.rcWork.top << " - " << monitorInfo.rcWork.right
              << ", " << monitorInfo.rcWork.bottom << std::endl;
    logStream << "Cursor position: " << cursorPos.x << ", " << cursorPos.y
              << std::endl;
    origin.x = (std::min)(cursorPos.x + offsetX,
                          (LONG)(monitorInfo.rcWork.right - scaledSize.width));
    origin.y = (std::min)(cursorPos.y + offsetY,
                          (LONG)(monitorInfo.rcWork.bottom - scaledSize.height -
                                 60)); // 60px for taskbar

    // Ensure window doesn't go off screen to the left/top
    origin.x = (std::max)((LONG)origin.x, monitorInfo.rcWork.left);
    origin.y = (std::max)((LONG)origin.y, monitorInfo.rcWork.top);

    logStream << "Calculated position: " << origin.x << ", " << origin.y
              << std::endl;
    origin.x = static_cast<LONG>(origin.x / dpiScale);
    origin.y = static_cast<LONG>(origin.y / dpiScale);

    logStream << "Final position (after DPI scaling): " << origin.x << ", "
              << origin.y << std::endl;
    logStream.flush();

    return origin;
}

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
    SetupLogFile();
    if (enableDebugConsole && AllocConsole()) {
        FILE *unused;
        if (freopen_s(&unused, "CONIN$", "r", stdin) == 0 &&
            freopen_s(&unused, "CONOUT$", "w", stdout) == 0 &&
            freopen_s(&unused, "CONOUT$", "w", stderr) == 0) {
            std::ios::sync_with_stdio(true);
            // Set console title
            SetConsoleTitle(L"Cylonix Debug Console");
            // Move console to a visible position
            HWND consoleWindow = GetConsoleWindow();
            if (consoleWindow) {
                SetWindowPos(consoleWindow, 0, 0, 0, 800, 600, SWP_NOZORDER);
            }
        }
        logStream << "Cylonix debug console initialized\n";
    }

    // Attach to console when present (e.g., 'flutter run') or create a
    // new console when running with a debugger.
    if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
        CreateAndAttachConsole();
    }

    logStream << GetTimestampString() << "Cylonix application starting...\n";

    // Initialize COM, so that it is available for use in the library and/or
    // plugins.
    ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

    flutter::DartProject project(L"data");

    std::vector<std::string> command_line_arguments = GetCommandLineArguments();

    // Check if this is a share window
    bool isShareWindow = false;
    logStream << "Command line arguments:";
    for (const auto &arg : command_line_arguments) {
        logStream << "'" << arg << "'";
    }
    logStream << std::endl;
    for (const auto &arg : command_line_arguments) {
        std::string trimmedArg = trim(arg);
        logStream << "Checking arg: '" << trimmedArg << "'" << std::endl;
        if (trimmedArg == "--share") {
            isShareWindow = true;
            logStream << L"Detected share window mode\n";
            break;
        } else {
            logStream << "not '--share' arg='" << arg << "'" << std::endl;
        }
    }
    logStream.flush();

    project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

    FlutterWindow window(project);
    Win32Window::Point origin(80, 20);
    Win32Window::Size size(1180, 700);
    HANDLE mutex = nullptr;
    if (isShareWindow) {
        mutex = CreateMutexW(nullptr, TRUE, L"CylonixSingleInstanceMutex");
        if (GetLastError() == ERROR_ALREADY_EXISTS) {
            logStream << GetTimestampString()
                      << "Finding existing instance HWND: " << std::endl;
            HWND hwnd = nullptr;
            for (int attempt = 0; attempt < 3; ++attempt) {
                hwnd = FindWindowW(nullptr, L"Send Files with Cylonix");
                logStream << "FindWindowW attempt " << (attempt + 1)
                          << ": HWND=" << hwnd << std::endl;
                if (hwnd)
                    break;
                if (attempt < 2) {
                    logStream << "Window not found, retrying in 1 second...\n";
                    logStream.flush();
                    Sleep(1000);
                }
            }
            logStream << GetTimestampString()
                      << "Found existing instance HWND: " << hwnd << std::endl;
            if (hwnd) {
                SetForegroundWindow(hwnd);
                std::wstring cmd_line(command_line);
                logStream << "Sending command line to existing instance\n";
                COPYDATASTRUCT cds;
                cds.dwData = 0;
                cds.cbData = static_cast<DWORD>((cmd_line.length() + 1) *
                                                sizeof(wchar_t));
                cds.lpData = (PVOID)cmd_line.c_str();
                bool sent = false;
                for (int attempt = 0; attempt < 3 && hwnd; ++attempt) {
                    LRESULT result =
                        SendMessageW(hwnd, WM_COPYDATA, 0, (LPARAM)&cds);
                    if (result) {
                        sent = true;
                        logStream << "Sent command line to existing instance: '"
                                  << Utf8FromUtf16(cmd_line.c_str()) << "' "
                                  << "Attempt: " << (attempt + 1)
                                  << std::endl;
                        break;
                    }
                    Sleep(500); // Wait half a second before retrying
                }
                if (!sent) {
                    logStream << "Failed to send WM_COPYDATA after retries.\n";
                }
            }
            logStream.flush();
            CloseHandle(mutex);
            return 0; // Exit the new instance
        }

        logStream << "Creating share window with custom size\n";
        size = Win32Window::Size(600, 700);
        // Get startup info which includes window position
        STARTUPINFO si = {sizeof(STARTUPINFO)};
        GetStartupInfo(&si);
        logStream << "Startup info retrieved, checking position flags: "
                  << si.dwFlags << std::endl;

        // Check if Windows provided positioning info
        if (si.dwFlags & STARTF_USEPOSITION) {
            logStream << "Using provided position from STARTUPINFO: " << si.dwX
                      << ", " << si.dwY << std::endl;
            origin.x = si.dwX;
            origin.y = si.dwY;
        } else {
            logStream << "No position provided, calculating based on cursor\n";
            origin = GetWindowPosition(size);
        }
        logStream.flush();
    }
    const wchar_t *windowTitle =
        isShareWindow ? L"Send Files With Cylonix" : L"Cylonix";
    if (!window.CreateAndShow(windowTitle, origin, size)) {
        if (mutex != nullptr) {
            ReleaseMutex(mutex);
            CloseHandle(mutex);
        }
        return EXIT_FAILURE;
    }

    window.SetQuitOnClose(true);

    logStream << GetTimestampString() << "Cylonix application started\n";
    logStream.flush();

    ::MSG msg;
    while (::GetMessage(&msg, nullptr, 0, 0)) {
        ::TranslateMessage(&msg);
        ::DispatchMessage(&msg);
    }

    ::CoUninitialize();

    logStream << GetTimestampString() << "Cylonix application exited\n";
    logStream.flush();
    logStream.close();
    if (mutex != nullptr) {
        ReleaseMutex(mutex);
        CloseHandle(mutex);
    }
    return EXIT_SUCCESS;
}
