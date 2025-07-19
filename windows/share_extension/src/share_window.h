#pragma once
#include <windows.h>
#include <vector>
#include <filesystem>
#include "share_handler.h"

class ShareWindow {
public:
    ShareWindow(const std::vector<std::filesystem::path>& files);
    ~ShareWindow();

    bool Create();
    void Show(int nCmdShow);
    void UpdateProgress(int percent);
    void UpdateStatus(const std::wstring& status);

private:
    static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp);
    LRESULT HandleMessage(UINT msg, WPARAM wp, LPARAM lp);
    void InitializeControls();
    void LoadPeerList();
    void OnSendButtonClicked();

    HWND m_hwnd;
    HWND m_peerList;
    HWND m_sendButton;
    HWND m_progress;
    HWND m_statusText;

    ShareHandler m_handler;
    std::vector<std::filesystem::path> m_files;
    std::vector<PeerStatus> m_peers;

    static constexpr const wchar_t* WINDOW_CLASS = L"CylonixShareWindow";
    void DebugLog(const wchar_t* format, ...) {
        wchar_t buffer[1024];
        va_list args;
        va_start(args, format);
        StringCbVPrintfW(buffer, sizeof(buffer), format, args);
        va_end(args);
        OutputDebugStringW(buffer);
        OutputDebugStringW(L"\n");
    }
};