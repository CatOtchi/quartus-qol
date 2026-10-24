/* Standalone native installer warning. No changes are made by this helper.
 * Exit 0 acknowledges; Cancel/Escape/close return 2; failures return 3. */
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define _WIN32_WINNT 0x0600
#include <windows.h>
#include <commctrl.h>
#include <shellapi.h>
#include <stdio.h>
int WINAPI wWinMain(HINSTANCE instance,HINSTANCE previous,LPWSTR command,int show) {
 (void)instance;(void)previous;(void)command;(void)show;
 int argc=0;LPWSTR *argv=CommandLineToArgvW(GetCommandLineW(),&argc);
 if(!argv||argc!=3){if(argv)LocalFree(argv);return 3;}
 wchar_t content[4096];
 _snwprintf(content,4095,L"Tested: Quartus Prime Lite 24.1std build 1077 (Windows x64).\nDetected editor version: %ls\nFolder: %ls\n\nCompatibility is not guaranteed. The extension may fail to load or crash Quartus. Continuing enables an experimental attempt for these exact binaries. Internal interface checks remain active.",argv[1],argv[2]);
 content[4095]=0;
 const TASKDIALOG_BUTTON buttons[]={{IDCANCEL,L"Cancel"},{100,L"I understand and continue"}};
 TASKDIALOGCONFIG config={0};config.cbSize=sizeof(config);
 config.dwFlags=TDF_ALLOW_DIALOG_CANCELLATION|TDF_SIZE_TO_CONTENT;
 config.pszWindowTitle=L"Quartus QOL - untested Quartus version";
 config.pszMainIcon=TD_WARNING_ICON;
 config.pszMainInstruction=L"You have a different or untested Quartus build";
 config.pszContent=content;config.cButtons=2;config.pButtons=buttons;
 config.nDefaultButton=IDCANCEL;
 int selected=IDCANCEL;HRESULT result=TaskDialogIndirect(&config,&selected,NULL,NULL);
 LocalFree(argv);if(FAILED(result))return 3;
 return selected==100?0:2;
}
