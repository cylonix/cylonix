#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif

#include "share_handler.h"
#include <appmodel.h>
#include <shobjidl_core.h>
#include <shlobj_core.h>
#include <winrt/Windows.ApplicationModel.DataTransfer.ShareTarget.h>
#include <winrt/Windows.Storage.h>
#include <iostream>
#include <winhttp.h>
#include <string>
#pragma comment(lib, "winhttp.lib")

#define WINHTTP_ACCESS_TYPE_NAMED_PIPE 0x00000040
#define WINHTTP_OPTION_NAMED_PIPE       0x0001000B
#define WINHTTP_OPTION_NAMED_PIPE_NAME  0x0001000C

std::filesystem::path ShareHandler::GetSharedContainer() {
    PWSTR path;
    if (SUCCEEDED(SHGetKnownFolderPath(FOLDERID_ProgramData, 0, NULL, &path))) {
        std::filesystem::path containerPath = path;
        CoTaskMemFree(path);
        containerPath /= L"Cylonix\\Share";
        std::filesystem::create_directories(containerPath);
        return containerPath;
    }
    return L"";
}

std::vector<PeerStatus> ShareHandler::LoadPeerStatus() {
    std::vector<PeerStatus> peers;
    try {
        std::string response = SendLocalHttpRequest("status", "GET");
        ParsePeerStatus(response, peers);
    } catch (const std::exception& e) {
        std::cout << "Failed to load peer status: " << e.what() << "\n";
    }
    return peers;
}
std::string ShareHandler::SendLocalHttpRequest(const std::string& path,
                                             const std::string& method,
                                             const std::string& body) {
    std::cout << "Initializing WinHTTP with impersonation...\n";

     // Use direct string literal for pipe path
    const wchar_t* pipeName = L"\\\\.\\pipe\\ProtectedPrefix\\Administrators\\Cylonix\\cylonixd";
    std::cout << "Using pipe path: \\\\.\\pipe\\ProtectedPrefix\\Administrators\\Cylonix\\cylonixd\n";

    // First initialize with named pipe access type
    HINTERNET hSession = WinHttpOpen(L"Cylonix Share/1.0",
                                   WINHTTP_ACCESS_TYPE_NAMED_PIPE,  // Changed back to NAMED_PIPE
                                   pipeName,  // Pass pipe path directly here
                                   WINHTTP_NO_PROXY_NAME,
                                   0);

    if (!hSession) {
        DWORD error = GetLastError();
        std::cout << "WinHttpOpen failed with error: " << error << "\n";
        throw std::runtime_error("Failed to initialize WinHTTP. Error: " +
                               std::to_string(error));
    }

    // Configure option for named pipe
    DWORD options = WINHTTP_OPTION_NAMED_PIPE | SECURITY_IMPERSONATION;
    if (!WinHttpSetOption(hSession,
                         WINHTTP_OPTION_CONNECT_RETRIES,
                         &options,
                         sizeof(options))) {
        DWORD error = GetLastError();
        std::cout << "WinHttpSetOption failed with error: " << error << "\n";
        WinHttpCloseHandle(hSession);
        throw std::runtime_error("Failed to set named pipe options. Error: " +
                               std::to_string(error));
    }

    // Set timeouts
    DWORD timeout = 30000;
    WinHttpSetTimeouts(hSession, timeout, timeout, timeout, timeout);

    // Create connection using the special host name
    HINTERNET hConnect = WinHttpConnect(hSession,
                                      L"local-tailscaled.sock",
                                      0,
                                      0);

    if (!hConnect) {
        DWORD error = GetLastError();
        std::cout << "WinHttpConnect failed with error: " << error << "\n";
        WinHttpCloseHandle(hSession);
        throw std::runtime_error("Failed to connect to local API. Error: " +
                               std::to_string(error));
    }

    // Convert path and method to wide strings using Windows API
    int wideLength = MultiByteToWideChar(CP_UTF8, 0, method.c_str(), -1, nullptr, 0);
    std::vector<wchar_t> wmethod(wideLength);
    MultiByteToWideChar(CP_UTF8, 0, method.c_str(), -1, wmethod.data(), wideLength);

    wideLength = MultiByteToWideChar(CP_UTF8, 0, path.c_str(), -1, nullptr, 0);
    std::vector<wchar_t> wpath(wideLength + 12); // +12 for "/localapi/v0/"
    wcscpy_s(wpath.data(), wpath.size(), L"/localapi/v0/");
    MultiByteToWideChar(CP_UTF8, 0, path.c_str(), -1,
                       wpath.data() + 12, wideLength);

    // Create request
    HINTERNET hRequest = WinHttpOpenRequest(hConnect,
                                          wmethod.data(),
                                          wpath.data(),
                                          NULL,
                                          WINHTTP_NO_REFERER,
                                          WINHTTP_DEFAULT_ACCEPT_TYPES,
                                          0);

    if (!hRequest) {
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        throw std::runtime_error("Failed to create request");
    }

    // Send request
    if (!WinHttpSendRequest(hRequest,
                           L"Content-Type: application/json\r\n",
                           -1,
                           (LPVOID)body.c_str(),
                           body.length(),
                           body.length(),
                           0)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        throw std::runtime_error("Failed to send request");
    }

    // Receive response
    if (!WinHttpReceiveResponse(hRequest, NULL)) {
        WinHttpCloseHandle(hRequest);
        WinHttpCloseHandle(hConnect);
        WinHttpCloseHandle(hSession);
        throw std::runtime_error("Failed to receive response");
    }

    // Read response data
    std::string response;
    DWORD bytesAvailable = 0;
    do {
        WinHttpQueryDataAvailable(hRequest, &bytesAvailable);
        if (bytesAvailable == 0) break;

        char* buffer = new char[bytesAvailable];
        DWORD bytesRead = 0;
        if (WinHttpReadData(hRequest, buffer, bytesAvailable, &bytesRead)) {
            response.append(buffer, bytesRead);
        }
        delete[] buffer;
    } while (bytesAvailable > 0);

    // Cleanup
    WinHttpCloseHandle(hRequest);
    WinHttpCloseHandle(hConnect);
    WinHttpCloseHandle(hSession);

    return response;
}
void ShareHandler::SendFilesToPeer(const std::wstring& peerId,
                                 const std::vector<std::filesystem::path>& files,
                                 ProgressCallback progress,
                                 StatusCallback status) {
    try {
        nlohmann::json request;

        // Convert peerId to UTF-8 using Windows API
        int utf8Length = WideCharToMultiByte(CP_UTF8, 0, peerId.c_str(), -1,
                                           nullptr, 0, nullptr, nullptr);
        std::string utf8PeerId(utf8Length - 1, 0);
        WideCharToMultiByte(CP_UTF8, 0, peerId.c_str(), -1,
                           utf8PeerId.data(), utf8Length, nullptr, nullptr);
        request["peer_id"] = utf8PeerId;

        request["files"] = nlohmann::json::array();

        for (const auto& file : files) {
            // Convert path to UTF-8
            const std::wstring& wpath = file.wstring();
            utf8Length = WideCharToMultiByte(CP_UTF8, 0, wpath.c_str(), -1,
                                           nullptr, 0, nullptr, nullptr);
            std::string utf8Path(utf8Length - 1, 0);
            WideCharToMultiByte(CP_UTF8, 0, wpath.c_str(), -1,
                               utf8Path.data(), utf8Length, nullptr, nullptr);
            request["files"].push_back(utf8Path);
        }

        std::string response = SendLocalHttpRequest(
            "send_files_to_peer",
            "POST",
            request.dump()
        );

        if (response != "Success") {
            throw std::runtime_error("Failed to send files: " + response);
        }

        if (status) status(L"Files sent successfully");
    } catch (const std::exception& e) {
        // Convert error message from UTF-8 to wide string
        std::string errMsg = e.what();
        int wideLength = MultiByteToWideChar(CP_UTF8, 0, errMsg.c_str(), -1,
                                           nullptr, 0);
        std::wstring wErrMsg(wideLength - 1, 0);
        MultiByteToWideChar(CP_UTF8, 0, errMsg.c_str(), -1,
                           wErrMsg.data(), wideLength);

        if (status) status(L"Failed to send files: " + wErrMsg);
    }
}
void ShareHandler::ParsePeerStatus(const std::string& jsonStr, std::vector<PeerStatus>& peers) {
    try {
        auto j = nlohmann::json::parse(jsonStr);
        for (const auto& peer : j["peers"]) {
            PeerStatus status;
            status.id = std::wstring(peer["id"].get<std::string>().begin(),
                                   peer["id"].get<std::string>().end());
            status.name = std::wstring(peer["name"].get<std::string>().begin(),
                                     peer["name"].get<std::string>().end());
            status.online = peer["online"].get<bool>();
            peers.push_back(status);
        }
    } catch (...) {
        // Handle JSON parsing errors
    }
}
void ShareHandler::SendFileRequest(HANDLE pipe, const std::wstring& peerId,
                                 const std::vector<std::filesystem::path>& files) {
    nlohmann::json request;
    request["method"] = "send_files_to_peer";

    // Convert wide string to UTF-8
    int utf8Length = WideCharToMultiByte(CP_UTF8, 0, peerId.c_str(), -1,
                                       nullptr, 0, nullptr, nullptr);
    std::string utf8PeerId(utf8Length - 1, 0); // -1 to skip null terminator
    WideCharToMultiByte(CP_UTF8, 0, peerId.c_str(), -1,
                       utf8PeerId.data(), utf8Length, nullptr, nullptr);
    request["peer_id"] = utf8PeerId;

    request["files"] = nlohmann::json::array();

    for (const auto& file : files) {
        // Convert path to UTF-8
        utf8Length = WideCharToMultiByte(CP_UTF8, 0, file.c_str(), -1,
                                       nullptr, 0, nullptr, nullptr);
        std::string utf8Path(utf8Length - 1, 0);
        WideCharToMultiByte(CP_UTF8, 0, file.c_str(), -1,
                           utf8Path.data(), utf8Length, nullptr, nullptr);
        request["files"].push_back(utf8Path);
    }

    std::string requestStr = request.dump();
    DWORD written;
    WriteFile(pipe, requestStr.c_str(), static_cast<DWORD>(requestStr.length()),
             &written, NULL);
}