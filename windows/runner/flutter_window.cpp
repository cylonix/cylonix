#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "flutter/method_channel.h"
#include "flutter/standard_method_codec.h"
#include "utils.h"

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

// Channel name for platform messaging
static const std::string kChannelName = "io.cylonix.sase/share_channel";

// Helper function to convert wchar_t* to std::string (UTF-8)
std::string WideToNarrow(const wchar_t* wide_str) {
  if (!wide_str) return "";
  int len = WideCharToMultiByte(CP_UTF8, 0, wide_str, -1, nullptr, 0, nullptr, nullptr);
  if (len == 0) return "";
  std::string narrow_str(len, 0);
  WideCharToMultiByte(CP_UTF8, 0, wide_str, -1, &narrow_str[0], len, nullptr, nullptr);
  if (!narrow_str.empty() && narrow_str.back() == '\0') {
    narrow_str.pop_back();
  }
  return narrow_str;
}


LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // WM_COPYDATA from another cylonix.exe process. dwData tells what the
  // payload (a UTF-16 string) is:
  //   0: a `--share ...` command line for the share window, which adds the
  //      file to the send sheet (`onShare`);
  //   1: the path of a share-request manifest for the main window, handed
  //      over by a share window for the Peer Message path
  //      (`onShareRequest`).
  if (message == WM_COPYDATA && flutter_controller_) {
    logStream << "Received WM_COPYDATA message\n";
    logStream.flush();

    COPYDATASTRUCT* cds = (COPYDATASTRUCT*)lparam;
    if (cds->lpData) {
      std::wstring payload((wchar_t*)cds->lpData, cds->cbData / sizeof(wchar_t));
      std::string narrow_payload = WideToNarrow(payload.c_str());
      const char* method = cds->dwData == 1 ? "onShareRequest" : "onShare";

      logStream << "Received " << method << ": '" << narrow_payload << "'\n";

      flutter::MethodChannel<> method_channel_{
        flutter_controller_->engine()->messenger(),
        kChannelName,
        &flutter::StandardMethodCodec::GetInstance()
      };
      method_channel_.InvokeMethod(
        method,
        std::make_unique<flutter::EncodableValue>(narrow_payload)
      );
      SetForegroundWindow(hwnd);
      return TRUE;
    }
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
