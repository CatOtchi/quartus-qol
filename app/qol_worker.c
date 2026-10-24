/* Start tools with a clean Windows DLL search directory before Python imports
 * any extension modules. Doing this inside Python is too late for _ctypes. */
#include <windows.h>
#include <wchar.h>
#include <stdlib.h>
int wmain(int argc,wchar_t**argv){
 (void)argc;(void)argv;
 /* Console subsystem: Tcl's WaitForInputIdle returns immediately. Tcl hides
    this pipe helper; no GUI queue or five-second idle timeout is involved. */
 wchar_t *args=GetCommandLineW();
 if(*args==L'"'){args++;while(*args&&*args!=L'"')args++;if(*args)args++;}
 else {while(*args&&*args!=L' '&&*args!=L'\t')args++;}
 while(*args==L' '||*args==L'\t')args++;
 SetDllDirectoryW(L"");
 SetEnvironmentVariableW(L"TCL_LIBRARY",NULL);
 SetEnvironmentVariableW(L"TK_LIBRARY",NULL);
 SetEnvironmentVariableW(L"TCLLIBPATH",NULL);
 STARTUPINFOW startup={0};startup.cb=sizeof(startup);
 startup.dwFlags=STARTF_USESTDHANDLES;
 SECURITY_ATTRIBUTES security={sizeof(security),NULL,TRUE};
 HANDLE input=CreateFileW(L"NUL",GENERIC_READ,FILE_SHARE_READ|FILE_SHARE_WRITE,&security,OPEN_EXISTING,0,NULL);
 startup.hStdInput=input;
 startup.hStdOutput=GetStdHandle(STD_OUTPUT_HANDLE);
 startup.hStdError=startup.hStdOutput;
 PROCESS_INFORMATION child={0};
 wchar_t *command=_wcsdup(args);if(!command)return 1;
 BOOL ok=CreateProcessW(NULL,command,NULL,NULL,TRUE,CREATE_NO_WINDOW,NULL,NULL,&startup,&child);
 free(command);CloseHandle(input);if(!ok)return (int)GetLastError();
 CloseHandle(child.hThread);WaitForSingleObject(child.hProcess,INFINITE);
 DWORD code=1;GetExitCodeProcess(child.hProcess,&code);CloseHandle(child.hProcess);
 return (int)code;
}
