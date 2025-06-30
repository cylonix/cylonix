#include <windows.h>
#include <shellapi.h>
#include <vector>
#include <filesystem>
#include <iostream>
#include "share_window.h"

// Helper function to parse command line arguments
std::vector<std::filesystem::path> ParseSharedFiles(PWSTR cmdLine) {
    std::vector<std::filesystem::path> files;
    int argc = 0;
    LPWSTR* argv = CommandLineToArgvW(cmdLine, &argc);

    if (argv) {
        // Skip first arg (program name) if present
        for (int i = (argc > 1 ? 1 : 0); i < argc; i++) {
            files.emplace_back(argv[i]);
        }
        LocalFree(argv);
    }

    return files;
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                    PWSTR pCmdLine, int nCmdShow) {
    // Parse shared files from command line
    std::vector<std::filesystem::path> sharedFiles = ParseSharedFiles(pCmdLine);

    // Create and run share window
    ShareWindow window(sharedFiles);
     std::cout << "Window object created, calling Create()...\n";

    if (!window.Create()) {
        std::cout << "Failed to create window!\n";
        return 1;
    }

    std::cout << "Window created, showing...\n";
    window.Show(nCmdShow);

    // Message loop
    MSG msg = {};
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    return 0;
}