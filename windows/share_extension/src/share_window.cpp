#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include "share_window.h"
#include <commctrl.h>
#include "resource.h"
#include <strsafe.h>
#include <iostream>
#include <shlwapi.h>
#pragma comment(lib, "shlwapi.lib")

// Initialize Common Controls
#pragma comment(lib, "comctl32.lib")
#pragma comment(linker,"\"/manifestdependency:type='win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'\"")

ShareWindow::ShareWindow(const std::vector<std::filesystem::path>& files)
    : m_files(files), m_hwnd(nullptr) {
    AllocConsole();
    FILE* dummy;
    freopen_s(&dummy, "CONOUT$", "w", stdout);

    std::cout << "ShareWindow constructor called with " << files.size() << " files\n";
}

ShareWindow::~ShareWindow() {
    if (m_hwnd) {
        DestroyWindow(m_hwnd);
    }
}
bool ShareWindow::Create() {
    std::cout << "Creating window...\n";

    // Register window class
    WNDCLASS wc = {};
    wc.lpfnWndProc = WndProc;
    wc.hInstance = GetModuleHandle(NULL);
    wc.lpszClassName = WINDOW_CLASS;
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.hCursor = LoadCursor(NULL, IDC_ARROW);
    wc.style = CS_HREDRAW | CS_VREDRAW;

    SetProcessDPIAware();

    if (!RegisterClass(&wc)) {
        std::cout << "Failed to register window class. Error: " << GetLastError() << "\n";
        return false;
    }

    HWND hwnd = CreateWindow(  // Store in local variable first
        WINDOW_CLASS,
        L"Share with Cylonix",
        WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
        CW_USEDEFAULT, CW_USEDEFAULT,
        624, 700,
        NULL,
        NULL,
        GetModuleHandle(NULL),
        this
    );

    if (!hwnd) {
        std::cout << "Failed to create window. Error: " << GetLastError() << "\n";
        return false;
    }

    // Don't set m_hwnd here - it will be set in WM_CREATE
    std::cout << "CreateWindow returned: " << hwnd << "\n";
    return true;
}

LRESULT CALLBACK ShareWindow::WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp) {
    ShareWindow* window = reinterpret_cast<ShareWindow*>(GetWindowLongPtr(hwnd, GWLP_USERDATA));

    if (msg == WM_CREATE) {
        std::cout << "WM_CREATE received for hwnd: " << hwnd << "\n";
        CREATESTRUCT* cs = reinterpret_cast<CREATESTRUCT*>(lp);
        window = reinterpret_cast<ShareWindow*>(cs->lpCreateParams);
        SetWindowLongPtr(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(window));
        window->m_hwnd = hwnd;  // Add this line to set the handle
        std::cout << "Window handle set to: " << window->m_hwnd << "\n";
        window->InitializeControls();
        return 0;
    }

    if (window) {
        return window->HandleMessage(msg, wp, lp);
    }

    return DefWindowProc(hwnd, msg, wp, lp);
}

void ShareWindow::Show(int nCmdShow) {
    std::cout << "Showing window...\n";
    ShowWindow(m_hwnd, nCmdShow);
    UpdateWindow(m_hwnd);  // Add this to force immediate update
}

void ShareWindow::UpdateProgress(int percent) {
    SendMessage(m_progress, PBM_SETPOS, percent, 0);
}

void ShareWindow::UpdateStatus(const std::wstring& status) {
    SetWindowText(m_statusText, status.c_str());
}

LRESULT ShareWindow::HandleMessage(UINT msg, WPARAM wp, LPARAM lp) {
    switch (msg) {
        case WM_COMMAND:
            if (LOWORD(wp) == IDC_SENDBUTTON) {
                OnSendButtonClicked();
            }
            return 0;

        case WM_DESTROY:
            PostQuitMessage(0);
            return 0;
    }
    return DefWindowProc(m_hwnd, msg, wp, lp);
}
void ShareWindow::InitializeControls() {
    std::cout << "Initializing controls...\n";
    if (!m_hwnd) {
        std::cout << "Error: Window handle is null!\n";
        return;
    }

    // Initialize common controls
    INITCOMMONCONTROLSEX icex = {};
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC = ICC_LISTVIEW_CLASSES | ICC_PROGRESS_CLASS;
    if (!InitCommonControlsEx(&icex)) {
        std::cout << "Failed to initialize common controls\n";
        return;
    }

    // Create system font
    NONCLIENTMETRICS ncm = { sizeof(NONCLIENTMETRICS) };
    SystemParametersInfo(SPI_GETNONCLIENTMETRICS, sizeof(NONCLIENTMETRICS), &ncm, 0);
    HFONT hFont = CreateFontIndirect(&ncm.lfMessageFont);

    // Create file header section
    std::wstring fileCount = m_files.size() == 1
        ? m_files[0].filename().wstring()
        : std::to_wstring(m_files.size()) + L" files";

    // Calculate total size
    LARGE_INTEGER totalSize = {0};
    for (const auto& file : m_files) {
        std::error_code ec;
        auto size = std::filesystem::file_size(file, ec);
        if (!ec) {
            totalSize.QuadPart += size;
        }
    }

    // Format size string
    wchar_t sizeStr[256];
    StrFormatByteSizeW(totalSize.QuadPart, sizeStr, ARRAYSIZE(sizeStr));
// Load file icon
    SHFILEINFO sfi = {};
    if (m_files.size() == 1) {
        SHGetFileInfo(m_files[0].c_str(), 0, &sfi, sizeof(sfi),
            SHGFI_ICON | SHGFI_LARGEICON);
    } else {
        // For multiple files, use folder icon
        SHGetFileInfo(L"folder", FILE_ATTRIBUTE_DIRECTORY, &sfi, sizeof(sfi),
            SHGFI_ICON | SHGFI_LARGEICON | SHGFI_USEFILEATTRIBUTES);
    }

    // Create header icon with proper size
    HWND headerIcon = CreateWindow(
        L"STATIC",
        L"",
        WS_CHILD | WS_VISIBLE | SS_ICON,
        16, 16, 48, 48,  // Increased size for large icon
        m_hwnd,
        NULL,
        GetModuleHandle(NULL),
        NULL
    );
    SendMessage(headerIcon, STM_SETICON, (WPARAM)sfi.hIcon, 0);

    // Create header text with increased height
    HWND headerText = CreateWindow(
        L"STATIC",
        fileCount.c_str(),
        WS_CHILD | WS_VISIBLE | SS_NOPREFIX,
        80, 16, 500, 32,  // Increased height and adjusted x position
        m_hwnd,
        NULL,
        GetModuleHandle(NULL),
        NULL
    );
    SendMessage(headerText, WM_SETFONT, (WPARAM)hFont, TRUE);

    HWND sizeText = CreateWindow(
        L"STATIC",
        sizeStr,
        WS_CHILD | WS_VISIBLE | SS_NOPREFIX,
        80, 48, 500, 32,  // Increased height and adjusted position
        m_hwnd,
        NULL,
        GetModuleHandle(NULL),
        NULL
    );
    SendMessage(sizeText, WM_SETFONT, (WPARAM)hFont, TRUE);

    // Adjust yOffset for more space
    int yOffset = 100;  // Increased from 80

    // Create peer list with more height
    m_peerList = CreateWindowEx(
        0,
        WC_LISTVIEW,
        L"",
        WS_CHILD | WS_VISIBLE | LVS_REPORT | LVS_SINGLESEL | WS_BORDER,
        10, yOffset + 10, 580, 380,  // Adjusted height
        m_hwnd,
        (HMENU)IDC_PEERLIST,
        GetModuleHandle(NULL),
        NULL
    );
    SendMessage(m_peerList, WM_SETFONT, (WPARAM)hFont, TRUE);
    ListView_SetExtendedListViewStyle(m_peerList,
        LVS_EX_FULLROWSELECT | LVS_EX_DOUBLEBUFFER);

    // Add columns to list view
    LVCOLUMN lvc = {};
    lvc.mask = LVCF_TEXT | LVCF_WIDTH;

    lvc.pszText = (LPWSTR)L"Name";
    lvc.cx = 300;  // Wider first column
    ListView_InsertColumn(m_peerList, 0, &lvc);

    lvc.pszText = (LPWSTR)L"Status";
    lvc.cx = 140;  // Wider status column
    ListView_InsertColumn(m_peerList, 1, &lvc);

   m_progress = CreateWindowEx(
        0,
        PROGRESS_CLASS,
        NULL,
        WS_CHILD | WS_VISIBLE,
        10, yOffset + 400, 440, 32,  // Increased height
        m_hwnd,
        (HMENU)IDC_PROGRESS,
        GetModuleHandle(NULL),
        NULL
    );

    // Create send button with increased size
    m_sendButton = CreateWindow(
        L"BUTTON",
        L"Send",
        WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
        460, yOffset + 400, 130, 32,  // Increased height
        m_hwnd,
        (HMENU)IDC_SENDBUTTON,
        GetModuleHandle(NULL),
        NULL
    );

    // Create status text with increased height
    m_statusText = CreateWindow(
        L"STATIC",
        L"",
        WS_CHILD | WS_VISIBLE | SS_NOPREFIX,
        10, yOffset + 442, 580, 40,  // Increased height
        m_hwnd,
        (HMENU)IDC_STATUSTEXT,
        GetModuleHandle(NULL),
        NULL
    );
    SendMessage(m_statusText, WM_SETFONT, (WPARAM)hFont, TRUE);

    LoadPeerList();
}
void ShareWindow::LoadPeerList() {
    ListView_DeleteAllItems(m_peerList);
    m_peers = m_handler.LoadPeerStatus();
    std::cout << "Loading peers..." << m_peers.size() << " peers found\n";

    for (const auto& peer : m_peers) {
        LVITEM lvi = {};
        lvi.mask = LVIF_TEXT;
        lvi.iItem = ListView_GetItemCount(m_peerList);

        lvi.iSubItem = 0;
        lvi.pszText = (LPWSTR)peer.name.c_str();
        int index = ListView_InsertItem(m_peerList, &lvi);

        lvi.iSubItem = 1;
        lvi.pszText = (LPWSTR)(peer.online ? L"Online" : L"Offline");
        ListView_SetItem(m_peerList, &lvi);
    }
}

void ShareWindow::OnSendButtonClicked() {
    int selectedIndex = ListView_GetNextItem(m_peerList, -1, LVNI_SELECTED);
    if (selectedIndex == -1) {
        UpdateStatus(L"Please select a peer");
        return;
    }

    EnableWindow(m_sendButton, FALSE);

    const auto& peer = m_peers[selectedIndex];
    m_handler.SendFilesToPeer(
        peer.id,
        m_files,
        [this](int progress) { UpdateProgress(progress); },
        [this](const std::wstring& status) { UpdateStatus(status); }
    );

    EnableWindow(m_sendButton, TRUE);
}
