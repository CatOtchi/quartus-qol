/* Quartus initializes Tcl before installing its GUI notifier. Timers created
 * during qui_init can otherwise sleep until the first Tcl console evaluation.
 * Service pending Tcl events from the existing GUI thread's Windows message
 * loop. No worker thread touches Tcl or the editor. */
#include <windows.h>
#include <stdint.h>
#include <string.h>
typedef struct Tcl_Interp Tcl_Interp;
typedef struct Tcl_Obj Tcl_Obj;
typedef int (*ObjCmd)(void*,Tcl_Interp*,int,Tcl_Obj*const*);
static int (*do_event)(int);
static void *(*create_command)(Tcl_Interp*,const char*,ObjCmd,void*,void*);
static void (*set_result)(Tcl_Interp*,Tcl_Obj*);
static Tcl_Obj *(*new_int)(int64_t);
static UINT_PTR timer;
static int pumping;
static void CALLBACK tick(HWND window,UINT message,UINT_PTR id,DWORD time) {
 (void)window;(void)message;(void)id;(void)time;
 if(pumping)return;
 pumping=1;
 /* TCL_DONT_WAIT=2. Bound each tick so normal Qt input remains responsive. */
 for(int n=0;n<16&&do_event(2);n++){}
 pumping=0;
}
static int status(void*d,Tcl_Interp*i,int ac,Tcl_Obj*const*av){
 (void)d;(void)ac;(void)av;set_result(i,new_int(timer!=0));return 0;
}
__declspec(dllexport) int Qolpump_Init(Tcl_Interp*i){
 HMODULE t=GetModuleHandleA("tcl86.dll");if(!t)return 1;
 do_event=(void*)GetProcAddress(t,"Tcl_DoOneEvent");
 create_command=(void*)GetProcAddress(t,"Tcl_CreateObjCommand");
 set_result=(void*)GetProcAddress(t,"Tcl_SetObjResult");
 new_int=(void*)GetProcAddress(t,"Tcl_NewWideIntObj");
 if(!do_event||!create_command||!set_result||!new_int)return 1;
 if(!timer)timer=SetTimer(NULL,0,25,tick);
 if(!timer)return 1;
 create_command(i,"qol_pump_active",status,NULL,NULL);
 return 0;
}
