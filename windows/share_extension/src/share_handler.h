#pragma once

#include <windows.h>
#include <filesystem>
#include <string>
#include <vector>
#include <functional>
#include <nlohmann/json.hpp>
#include <strsafe.h>

struct PeerStatus {
    std::wstring id;
    std::wstring name;
    bool online;
};

class ShareHandler {
public:
    using ProgressCallback = std::function<void(int)>;
    using StatusCallback = std::function<void(const std::wstring&)>;

    ShareHandler() = default;
    ~ShareHandler() = default;

    std::vector<PeerStatus> LoadPeerStatus();
    void SendFilesToPeer(const std::wstring& peerId,
                        const std::vector<std::filesystem::path>& files,
                        ProgressCallback progress = nullptr,
                        StatusCallback status = nullptr);

private:
    std::filesystem::path GetSharedContainer();
    void ParsePeerStatus(const std::string& jsonStr, std::vector<PeerStatus>& peers);
    void SendFileRequest(HANDLE pipe, const std::wstring& peerId,
                        const std::vector<std::filesystem::path>& files);
private:
    void DebugLog(const wchar_t* format, ...) {
        wchar_t buffer[1024];
        va_list args;
        va_start(args, format);
        StringCbVPrintfW(buffer, sizeof(buffer), format, args);
        va_end(args);
        OutputDebugStringW(buffer);
        OutputDebugStringW(L"\n");
    }
    std::string SendLocalHttpRequest(const std::string& path,
                                   const std::string& method,
                                   const std::string& body = "");
    static constexpr const wchar_t* PIPE_PATH = L"\\\\.\\pipe\\ProtectedPrefix\\Administrators\\Cylonix\\cylonixd";
    static constexpr const wchar_t* LOCAL_HOST = L"local-tailscaled.sock";
    static constexpr const wchar_t* LOCAL_API = L"/localapi/v0/";
};