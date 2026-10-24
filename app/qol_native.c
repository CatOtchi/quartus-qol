/* Quartus 24.1std build 1077 native editor bridge.
 * Loaded explicitly through Tcl; no binary patching, injection or global hooks.
 * Qt/MSVC aggregate layouts and two editor offsets are pinned to the verified DLL.
 */
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct Tcl_Interp Tcl_Interp;
typedef struct Tcl_Obj Tcl_Obj;
typedef int (__cdecl *ObjCmd)(void*,Tcl_Interp*,int,Tcl_Obj*const*);
#define API(ret,n,args) static ret (__cdecl *n) args
API(void*,Tcl_CreateObjCommand,(Tcl_Interp*,const char*,ObjCmd,void*,void*));
API(void,Tcl_SetObjResult,(Tcl_Interp*,Tcl_Obj*));
API(Tcl_Obj*,Tcl_NewStringObj,(const char*,int));
API(Tcl_Obj*,Tcl_NewUnicodeObj,(const uint16_t*,int));
API(Tcl_Obj*,Tcl_NewWideIntObj,(int64_t));
API(Tcl_Obj*,Tcl_NewListObj,(int,Tcl_Obj*const*));
API(int,Tcl_ListObjAppendElement,(Tcl_Interp*,Tcl_Obj*,Tcl_Obj*));
API(int,Tcl_ListObjGetElements,(Tcl_Interp*,Tcl_Obj*,int*,Tcl_Obj***));
API(int,Tcl_GetWideIntFromObj,(Tcl_Interp*,Tcl_Obj*,int64_t*));
API(char*,Tcl_GetStringFromObj,(Tcl_Obj*,int*));
API(unsigned char*,Tcl_GetByteArrayFromObj,(Tcl_Obj*,int*));
typedef struct {void *data; void **ptr; intptr_t size;} QtList;
typedef struct {void *data; uint16_t *ptr; intptr_t size;} QtString;
typedef struct {char buf[16]; uint64_t size,cap;} MsvcString;
typedef intptr_t (*SciFn)(void*,unsigned,uintptr_t,intptr_t);
typedef struct {int x,y;} QtPoint;
typedef struct {int x1,y1,x2,y2;} QtRect;
typedef struct {intptr_t start,end,line;int severity;char *message;} Diagnostic;
typedef struct DiagnosticFile {char *path;Diagnostic *rows;int count;struct DiagnosticFile *next;} DiagnosticFile;
static unsigned char *editor;
static void *(*get_app)(void);
static void *(*get_mgr)(void*);
static QtList *(*get_frames)(void*,QtList*,const MsvcString*);
static QtString *(*get_filepath)(void*,QtString*);
static QtString *(*get_filename)(void*,QtString*);
static void (*destroy_string)(QtString*);
static void (*deallocate)(void*,intptr_t,intptr_t);
static DWORD owner_thread;
static QtList *(*all_widgets)(QtList*);
static const char *(*class_name)(const void*);
static QtString *(*object_name)(void*,QtString*);
static void (*set_stylesheet)(void*,const QtString*);
static QtString *(*get_stylesheet)(void*,QtString*);
static void (*set_updates)(void*,int);
typedef struct {unsigned message;uintptr_t w;intptr_t l;} StyleMessage;
typedef struct Theme {void*frame;StyleMessage*messages;int count;intptr_t background;intptr_t original[256][3];intptr_t caret,line_back,line_visible,guides;struct Theme*next;} Theme;
static Theme*themes;
static void repair_theme(void*f);

static const char *widget_class(void*w){typedef void*(*Meta)(void*);Meta fn=*(Meta*)*(void**)w;return class_name(fn(w));}

static QtPoint *(*cursor_pos)(QtPoint*);
static QtPoint *(*map_global)(void*,QtPoint*,const QtPoint*);
static void *(*widget_at)(const QtPoint*);
static void *(*viewport_of)(void*);
static void *(*active_window)(void);
static void *(*window_of)(void*);
static void *(*parent_of)(void*);
static void (*string_from_utf8)(QtString*,const char*);
static void (*tooltip_show)(const QtPoint*,const QtString*,void*,const QtRect*,int);
static void (*tooltip_hide)(void);
static DiagnosticFile *diagnostic_files;
static void *hover_frame;
static intptr_t hover_line=-1,hover_caret=-1;
static ULONGLONG hover_since;
static int hover_visible,hover_count;
static int hover_delay=400;
static void hide_hover(void){if(hover_visible&&tooltip_hide)tooltip_hide();hover_visible=0;hover_count=0;}
static void reset_hover(void){hide_hover();hover_frame=NULL;hover_line=-1;hover_since=0;}
static char *copy_string(const char*s){size_t n=strlen(s)+1;char*r=malloc(n);if(r)memcpy(r,s,n);return r;}
static int fail(Tcl_Interp*i,const char*s){Tcl_SetObjResult(i,Tcl_NewStringObj(s,-1));return 1;}
static void append(Tcl_Interp*i,Tcl_Obj*l,Tcl_Obj*v){Tcl_ListObjAppendElement(i,l,v);}
static void pair(Tcl_Interp*i,Tcl_Obj*l,const char*k,Tcl_Obj*v){append(i,l,Tcl_NewStringObj(k,-1));append(i,l,v);}
static void free_list(QtList*l){if(l->data&&InterlockedDecrement((LONG*)l->data)==0)deallocate(l->data,sizeof(void*),sizeof(void*));}
static QtList frames(void){QtList l={0};MsvcString s={{0},8,15};memcpy(s.buf,"edt_tedq",8);get_frames(get_mgr(get_app()),&l,&s);return l;}
static void* engine(void*f){void*c=*(void**)((char*)f+0x248);if(!c)return NULL;void*d=*(void**)((char*)c+0x28);return d?(char*)d+0x10:NULL;}
static intptr_t sci(void*f,unsigned m,uintptr_t w,intptr_t l){void*e=engine(f);if(!e)return 0;SciFn send=*(SciFn*)((char*)*(void**)e+0x1e8);return send(e,m,w,l);}
static Theme*theme_for(void*f){for(Theme*t=themes;t;t=t->next)if(t->frame==f)return t;return NULL;}
static void apply_theme(Theme*t){for(int k=0;k<t->count;k++){StyleMessage*m=&t->messages[k];sci(t->frame,m->message,m->w,m->l);}}
static void repair_theme(void*f){Theme*t=theme_for(f);if(t&&(sci(f,2482,0,0)!=t->background||sci(f,2482,32,0)!=t->background||sci(f,2482,64,0)!=t->background))apply_theme(t);}
static void prune_themes(QtList*l){Theme**link=&themes;while(*link){Theme*t=*link;int found=0;for(intptr_t j=0;j<l->size;j++)if(l->ptr[j]==t->frame){found=1;break;}if(found)link=&t->next;else{*link=t->next;free(t->messages);free(t);}}}
static void updates(void*f,int enabled){void*c=*(void**)((char*)f+0x248);if(c&&set_updates)set_updates(c,enabled);}
static Tcl_Obj* path_obj(void*f){QtString s={0};get_filepath(f,&s);Tcl_Obj*r=Tcl_NewUnicodeObj(s.ptr,(int)s.size);destroy_string(&s);return r;}
static Tcl_Obj* text_obj(void*f){intptr_t n=sci(f,2006,0,0);if(n<0||n>16*1024*1024)return Tcl_NewStringObj("",0);char*b=malloc(n+1);sci(f,2182,n+1,(intptr_t)b);Tcl_Obj*r=Tcl_NewStringObj(b,(int)n);free(b);return r;}
static int same_path(const char*a,const char*b){while(*a&&*b){char x=*a++,y=*b++;if(x=='\\')x='/';if(y=='\\')y='/';if(x>='A'&&x<='Z')x+=32;if(y>='A'&&y<='Z')y+=32;if(x!=y)return 0;}return *a==*b;}
static char* frame_path(void*f){QtString s={0};get_filepath(f,&s);int n=WideCharToMultiByte(CP_UTF8,0,(WCHAR*)s.ptr,(int)s.size,NULL,0,NULL,NULL);char*p=calloc(n+1,1);if(p)WideCharToMultiByte(CP_UTF8,0,(WCHAR*)s.ptr,(int)s.size,p,n,NULL,NULL);destroy_string(&s);return p;}
static DiagnosticFile* diagnostics_for(const char*path,int create){
 for(DiagnosticFile*d=diagnostic_files;d;d=d->next)if(same_path(path,d->path))return d;
 if(!create)return NULL;
 DiagnosticFile*d=calloc(1,sizeof(*d));if(!d)return NULL;d->path=copy_string(path);d->next=diagnostic_files;diagnostic_files=d;return d;
}
static void forget_diagnostics(const char*path){
 DiagnosticFile**link=&diagnostic_files;
 while(*link){DiagnosticFile*d=*link;if(same_path(path,d->path)){*link=d->next;for(int k=0;k<d->count;k++)free(d->rows[k].message);free(d->rows);free(d->path);free(d);return;}link=&d->next;}
}
static int severity_level(const char*s){if(!strcmp(s,"warning"))return 1;if(!strcmp(s,"error")||!strcmp(s,"fatal"))return 0;return 2;}
static int compare_diagnostics(const void*a,const void*b){const Diagnostic*x=a,*y=b;if(x->severity!=y->severity)return x->severity-y->severity;if(x->start!=y->start)return x->start<y->start?-1:1;return strcmp(x->message,y->message);}
static char* hover_html(DiagnosticFile*d,intptr_t line,int*count){
 size_t capacity=256;*count=0;
 for(int k=0;k<d->count;k++)if(d->rows[k].line==line){capacity+=strlen(d->rows[k].message)*6+256;(*count)++;}
 char*html=calloc(capacity,1);if(!html)return NULL;
 strcat(html,"<qt><table cellspacing='0' cellpadding='5' width='550'>");
 for(int k=0;k<d->count;k++){
  Diagnostic*r=&d->rows[k];if(r->line!=line)continue;
  const char*name=r->severity==0?"Error":r->severity==1?"Warning":"Information";
  const char*color=r->severity==0?"#f14c4c":r->severity==1?"#d99000":"#3794ff";
  char header[256];snprintf(header,sizeof(header),"<tr><td><b><font color='%s'>%s</font></b> &middot; slang<br/>",color,name);strcat(html,header);
  const char*s=r->message;if(!strncmp(s,"slang: ",7))s+=7;
  char*out=html+strlen(html);
  while(*s){const char*escaped=NULL;switch(*s){case '&':escaped="&amp;";break;case '<':escaped="&lt;";break;case '>':escaped="&gt;";break;case '"':escaped="&quot;";break;case '\n':escaped="<br/>";break;case '\r':s++;continue;}
   if(escaped){size_t n=strlen(escaped);memcpy(out,escaped,n);out+=n;}else *out++=*s;s++;
  }*out=0;strcat(html,"</td></tr>");
 }
 strcat(html,"</table></qt>");return html;
}
static int widget_belongs_to(void*widget,void*viewport){for(int depth=0;widget&&depth<12;depth++,widget=parent_of(widget))if(widget==viewport)return 1;return 0;}
static void prune_diagnostics(QtList*l){
 DiagnosticFile*d=diagnostic_files;
 while(d){DiagnosticFile*next=d->next;int found=0;for(intptr_t j=0;j<l->size;j++){char*p=frame_path(l->ptr[j]);found=p&&same_path(p,d->path);free(p);if(found)break;}
  if(!found){char*p=copy_string(d->path);forget_diagnostics(p);free(p);}d=next;
 }
}
static void poll_hover(QtList*l){
 prune_diagnostics(l);
 QtPoint global={0};cursor_pos(&global);void*under=widget_at(&global);
 for(intptr_t j=0;j<l->size;j++){
  void*f=l->ptr[j];void*ctrl=*(void**)((char*)f+0x248);if(!ctrl)continue;void*viewport=viewport_of(ctrl);
  if(!viewport||!widget_belongs_to(under,viewport)||window_of(viewport)!=active_window())continue;
  if(sci(f,2159,0,0)){reset_hover();return;}
  QtPoint local={0};map_global(viewport,&local,&global);
  intptr_t pos=sci(f,2023,(uintptr_t)local.x,local.y);if(pos<0){reset_hover();return;}
  char*p=frame_path(f);DiagnosticFile*d=p?diagnostics_for(p,0):NULL;free(p);
  if(!d){reset_hover();return;}
  intptr_t line=sci(f,2166,pos,0);int hit=0;
  for(int k=0;k<d->count;k++)if(pos>=d->rows[k].start&&pos<d->rows[k].end){hit=1;break;}
  if(!hit){reset_hover();return;}
  intptr_t caret=sci(f,2008,0,0);
  if(f!=hover_frame||line!=hover_line||caret!=hover_caret){reset_hover();hover_frame=f;hover_line=line;hover_caret=caret;hover_since=GetTickCount64();}
  if(!hover_visible&&GetTickCount64()-hover_since>=(ULONGLONG)hover_delay){
   int count=0;char*html=hover_html(d,line,&count);if(!html)return;QtString text={0};string_from_utf8(&text,html);
   QtRect rect={0,0,-1,-1};tooltip_show(&global,&text,viewport,&rect,60000);destroy_string(&text);free(html);hover_visible=1;hover_count=count;
  }return;
 }reset_hover();
}
static void* find_frame(QtList*l,const char*p){for(intptr_t j=0;j<l->size;j++){QtString s={0};get_filepath(l->ptr[j],&s);int n=WideCharToMultiByte(CP_UTF8,0,(WCHAR*)s.ptr,(int)s.size,NULL,0,NULL,NULL);char*b=calloc(n+1,1);WideCharToMultiByte(CP_UTF8,0,(WCHAR*)s.ptr,(int)s.size,b,n,NULL,NULL);int eq=same_path(p,b);free(b);destroy_string(&s);if(eq)return l->ptr[j];}return NULL;}
static void clear_marks(void*f){intptr_t n=sci(f,2006,0,0);for(int id=29;id<=31;id++){sci(f,2500,id,0);sci(f,2505,0,n);}sci(f,2547,0,0);char*p=frame_path(f);if(p){forget_diagnostics(p);free(p);}if(f==hover_frame)reset_hover();}
#include "qol_options.inc"
static int command(void*d,Tcl_Interp*i,int ac,Tcl_Obj*const*av){
 (void)d;if(GetCurrentThreadId()!=owner_thread)return fail(i,"Editor access must run on the Quartus GUI thread");
 if(ac<2)return fail(i,"Usage: qol_native list|get|replace|mark|clear|save|send ...");
 const char*op=Tcl_GetStringFromObj(av[1],NULL);
 if(!strcmp(op,"options"))return options_command(i,ac,av);
 QtList l=frames();prune_themes(&l);for(intptr_t j=0;j<l.size;j++)if(engine(l.ptr[j]))repair_theme(l.ptr[j]);
 if(!strcmp(op,"version")){free_list(&l);Tcl_SetObjResult(i,Tcl_NewWideIntObj(13));return 0;}
 if(!strcmp(op,"widgets")){QtList ws={0};all_widgets(&ws);Tcl_Obj*r=Tcl_NewListObj(0,NULL);for(intptr_t k=0;k<ws.size;k++){void*w=ws.ptr[k];Tcl_Obj*row=Tcl_NewListObj(0,NULL);append(i,row,Tcl_NewStringObj(widget_class(w),-1));QtString n={0};object_name(w,&n);append(i,row,Tcl_NewUnicodeObj(n.ptr,(int)n.size));destroy_string(&n);append(i,r,row);}free_list(&ws);free_list(&l);Tcl_SetObjResult(i,r);return 0;}
 if(!strcmp(op,"widgetstyle")&&ac==4){const char*cls=Tcl_GetStringFromObj(av[2],NULL);QtString css={0};string_from_utf8(&css,Tcl_GetStringFromObj(av[3],NULL));QtList ws={0};all_widgets(&ws);int count=0;for(intptr_t k=0;k<ws.size;k++)if(!strcmp(widget_class(ws.ptr[k]),cls)){QtString old={0};get_stylesheet(ws.ptr[k],&old);int same=old.size==css.size&&!memcmp(old.ptr,css.ptr,(size_t)css.size*2);destroy_string(&old);if(!same)set_stylesheet(ws.ptr[k],&css);count++;}free_list(&ws);destroy_string(&css);free_list(&l);Tcl_SetObjResult(i,Tcl_NewWideIntObj(count));return 0;}
 if(!strcmp(op,"hover")){poll_hover(&l);free_list(&l);return 0;}
 if(!strcmp(op,"hidehover")){reset_hover();free_list(&l);return 0;}
 if(!strcmp(op,"hoverstatus")){Tcl_Obj*r=Tcl_NewListObj(0,NULL);pair(i,r,"visible",Tcl_NewWideIntObj(hover_visible));pair(i,r,"count",Tcl_NewWideIntObj(hover_count));pair(i,r,"line",Tcl_NewWideIntObj(hover_line+1));free_list(&l);Tcl_SetObjResult(i,r);return 0;}
 if(!strcmp(op,"hoverdelay")&&ac==3){int64_t delay;if(Tcl_GetWideIntFromObj(i,av[2],&delay)){free_list(&l);return 1;}if(delay<0||delay>5000){free_list(&l);return fail(i,"Hover delay must be 0..5000 ms");}hover_delay=(int)delay;free_list(&l);return 0;}
 if(!strcmp(op,"list")){Tcl_Obj*r=Tcl_NewListObj(0,NULL);for(intptr_t j=0;j<l.size;j++){void*f=l.ptr[j];if(!engine(f))continue;Tcl_Obj*o=Tcl_NewListObj(0,NULL);pair(i,o,"path",path_obj(f));pair(i,o,"modified",Tcl_NewWideIntObj(sci(f,2159,0,0)));pair(i,o,"length",Tcl_NewWideIntObj(sci(f,2006,0,0)));append(i,r,o);}free_list(&l);Tcl_SetObjResult(i,r);return 0;}
 if(ac<3){free_list(&l);return fail(i,"Missing editor path");}void*f=find_frame(&l,Tcl_GetStringFromObj(av[2],NULL));free_list(&l);if(!f||!engine(f))return fail(i,"File is not open in Quartus's native editor");
 if(!strcmp(op,"theme")&&ac==4){
  int count;Tcl_Obj**rows;if(Tcl_ListObjGetElements(i,av[3],&count,&rows))return 1;
  StyleMessage*messages=calloc((size_t)count,sizeof(*messages));if(count&&!messages)return fail(i,"Cannot allocate theme");
  intptr_t background=0;
  for(int k=0;k<count;k++){int n;Tcl_Obj**v;int64_t m,w,p;if(Tcl_ListObjGetElements(i,rows[k],&n,&v)||n!=3||Tcl_GetWideIntFromObj(i,v[0],&m)||Tcl_GetWideIntFromObj(i,v[1],&w)||Tcl_GetWideIntFromObj(i,v[2],&p)){free(messages);return fail(i,"Invalid theme message");}messages[k]=(StyleMessage){(unsigned)m,(uintptr_t)w,(intptr_t)p};if(m==2052&&w==0)background=(intptr_t)p;}
  Theme*t=theme_for(f);if(!t){t=calloc(1,sizeof(*t));if(!t){free(messages);return fail(i,"Cannot allocate theme cache");}t->frame=f;t->next=themes;themes=t;for(int k=0;k<256;k++){t->original[k][0]=sci(f,2481,k,0);t->original[k][1]=sci(f,2482,k,0);t->original[k][2]=sci(f,2484,k,0);}t->caret=sci(f,2138,0,0);t->line_back=sci(f,2097,0,0);t->line_visible=sci(f,2095,0,0);t->guides=sci(f,2133,0,0);}
  free(t->messages);t->messages=messages;t->count=count;t->background=background;
  updates(f,0);apply_theme(t);updates(f,1);return 0;
 }
 if(!strcmp(op,"restoretheme")){
  Theme**link=&themes;while(*link){Theme*t=*link;if(t->frame==f){
   updates(f,0);for(int k=0;k<256;k++){sci(f,2051,k,t->original[k][0]);sci(f,2052,k,t->original[k][1]);sci(f,2054,k,t->original[k][2]);}
   sci(f,2069,t->caret,0);sci(f,2098,t->line_back,0);sci(f,2096,t->line_visible,0);sci(f,2132,t->guides,0);
   *link=t->next;free(t->messages);free(t);sci(f,4003,0,-1);updates(f,1);break;
  }link=&t->next;}return 0;
 }
 if(!strcmp(op,"colorize")&&ac==5){
  int textn,stylen;const char*expected=Tcl_GetStringFromObj(av[3],&textn);unsigned char*styles=Tcl_GetByteArrayFromObj(av[4],&stylen);
  intptr_t n=sci(f,2006,0,0);if(n!=textn||n!=stylen)return fail(i,"Stale syntax colors discarded");
  char*current=malloc((size_t)n+1);if(!current)return fail(i,"Cannot allocate syntax buffer");sci(f,2182,n+1,(intptr_t)current);int eq=!memcmp(current,expected,n);free(current);if(!eq)return fail(i,"Stale syntax colors discarded");
  /* Let Quartus's lexer maintain folding, then apply the TextMate foregrounds.
     Styling does not change source, selection, undo history, or saved state. */
  updates(f,0);sci(f,4003,0,-1);repair_theme(f);sci(f,2032,0,0);sci(f,2073,n,(intptr_t)styles);updates(f,1);return 0;
 }
 if(!strcmp(op,"keywords")&&ac==5){int64_t group;if(Tcl_GetWideIntFromObj(i,av[3],&group))return 1;sci(f,4005,(uintptr_t)group,(intptr_t)Tcl_GetStringFromObj(av[4],NULL));sci(f,4003,0,-1);return 0;}
 if(!strcmp(op,"get")){Tcl_SetObjResult(i,text_obj(f));return 0;}
 if(!strcmp(op,"complete")&&ac==5){
  int64_t entered;if(Tcl_GetWideIntFromObj(i,av[3],&entered))return 1;
  intptr_t pos=sci(f,2008,0,0);
  if(entered<1||entered>pos||!sci(f,2381,0,0)||sci(f,2009,0,0)!=pos)return 0;
  sci(f,2106,' ',0);sci(f,2113,0,0);sci(f,2115,0,0);
  /* Tcl supplies ranked fuzzy candidates; do not apply prefix-only filtering.
     Explicit selection also supports engines predating SELECT_FIRST_ITEM. */
  sci(f,2660,2,0);sci(f,2638,2,0);sci(f,2118,0,0);
  sci(f,2270,1,0);sci(f,2208,44,0);sci(f,2210,8,0);
  sci(f,2100,(uintptr_t)entered,(intptr_t)Tcl_GetStringFromObj(av[4],NULL));
  sci(f,2108,0,(intptr_t)"");return 0;
 }
 if(!strcmp(op,"clear")){clear_marks(f);return 0;}
 if(!strcmp(op,"hovertext")&&ac==4){int64_t line;if(Tcl_GetWideIntFromObj(i,av[3],&line))return 1;char*p=frame_path(f);DiagnosticFile*d=p?diagnostics_for(p,0):NULL;free(p);int count=0;char*html=d?hover_html(d,line-1,&count):NULL;Tcl_SetObjResult(i,Tcl_NewStringObj(html?html:"",-1));free(html);return 0;}
 if(!strcmp(op,"send")&&ac>=4){int64_t m,w=0,p=0;if(Tcl_GetWideIntFromObj(i,av[3],&m))return 1;if(ac>4&&Tcl_GetWideIntFromObj(i,av[4],&w))return 1;if(ac>5&&Tcl_GetWideIntFromObj(i,av[5],&p))return 1;Tcl_SetObjResult(i,Tcl_NewWideIntObj(sci(f,(unsigned)m,(uintptr_t)w,(intptr_t)p)));return 0;}
 if(!strcmp(op,"save")){QtString s={0};get_filepath(f,&s);typedef int(*Save)(void*,QtString*);Save save=*(Save*)((char*)*(void**)f+0x1e8);updates(f,0);int ok=save(f,&s);repair_theme(f);updates(f,1);destroy_string(&s);return ok?0:fail(i,"Quartus could not save formatted file");}
 if(!strcmp(op,"replace")&&ac==5){int oldn,newn;const char*old=Tcl_GetStringFromObj(av[3],&oldn);const char*next=Tcl_GetStringFromObj(av[4],&newn);intptr_t n=sci(f,2006,0,0);if(n!=oldn)return fail(i,"Buffer changed; formatting discarded");char*b=malloc(n+1);sci(f,2182,n+1,(intptr_t)b);int eq=!memcmp(b,old,n);free(b);if(!eq||sci(f,2159,0,0))return fail(i,"Unsaved edits detected; formatting discarded");if(n==newn&&!memcmp(old,next,n))return 0;
  intptr_t pos=sci(f,2008,0,0),anchor=sci(f,2009,0,0),line=sci(f,2166,pos,0),col=sci(f,2129,pos,0),aline=sci(f,2166,anchor,0),acol=sci(f,2129,anchor,0),view=sci(f,2152,0,0);
  updates(f,0);clear_marks(f);sci(f,2078,0,0);sci(f,2190,0,0);sci(f,2192,n,0);sci(f,2194,newn,(intptr_t)next);sci(f,2079,0,0);
  intptr_t newpos=sci(f,2456,line,col),newanchor=sci(f,2456,aline,acol);sci(f,2160,newanchor,newpos);sci(f,2613,view,0);repair_theme(f);updates(f,1);return 0;
 }
 if(!strcmp(op,"mark")&&ac==4){int count;Tcl_Obj**rows;if(Tcl_ListObjGetElements(i,av[3],&count,&rows))return 1;clear_marks(f);
  for(int id=29;id<=31;id++){sci(f,2080,id,1);sci(f,2082,id,id==31?0x4c4cf1:id==30?0x0090d9:0xff9437);sci(f,2510,id,0);}
  sci(f,2548,0,0);
  char*path=frame_path(f);DiagnosticFile*d=path?diagnostics_for(path,1):NULL;free(path);if(!d)return fail(i,"Cannot allocate diagnostic store");
  d->rows=calloc((size_t)count,sizeof(Diagnostic));if(count&&!d->rows)return fail(i,"Cannot allocate diagnostics");
  for(int k=0;k<count;k++){int nc;Tcl_Obj**v;if(Tcl_ListObjGetElements(i,rows[k],&nc,&v)||nc!=5)continue;int64_t line,col,len;if(Tcl_GetWideIntFromObj(i,v[0],&line)||Tcl_GetWideIntFromObj(i,v[1],&col)||Tcl_GetWideIntFromObj(i,v[2],&len))continue;if(line<1||col<1)continue;
   intptr_t start=sci(f,2167,line-1,0);if(start<0)continue;intptr_t end=sci(f,2136,line-1,0);intptr_t at=start+col-1;if(at>end)at=end;if(len<1)len=1;if(at+len>end)len=end-at;if(len<1&&at>start){at--;len=1;}
   const char*severity=Tcl_GetStringFromObj(v[3],NULL);int level=severity_level(severity);const char*message=Tcl_GetStringFromObj(v[4],NULL);
   int duplicate=0;for(int n=0;n<d->count;n++)if(d->rows[n].start==at&&d->rows[n].end==at+len&&d->rows[n].severity==level&&!strcmp(d->rows[n].message,message)){duplicate=1;break;}if(duplicate)continue;
   Diagnostic*r=&d->rows[d->count++];r->start=at;r->end=at+len;r->line=line-1;r->severity=level;r->message=copy_string(message);
   sci(f,2500,31-level,0);sci(f,2504,at,len);
  }qsort(d->rows,(size_t)d->count,sizeof(Diagnostic),compare_diagnostics);return 0;
 }
 return fail(i,"Unknown command or wrong argument count");
}
__declspec(dllexport) int Qolnative_Init(Tcl_Interp*i){
 HMODULE t=GetModuleHandleA("tcl86.dll");if(!t)return 1;
#define BIND(n) n=(void*)GetProcAddress(t,#n);if(!n)return 1
 BIND(Tcl_CreateObjCommand);BIND(Tcl_SetObjResult);BIND(Tcl_NewStringObj);BIND(Tcl_NewUnicodeObj);BIND(Tcl_NewWideIntObj);BIND(Tcl_NewListObj);BIND(Tcl_ListObjAppendElement);BIND(Tcl_ListObjGetElements);BIND(Tcl_GetWideIntFromObj);BIND(Tcl_GetStringFromObj);BIND(Tcl_GetByteArrayFromObj);
 editor=(unsigned char*)GetModuleHandleA("edt_tedq.dll");if(!editor)return fail(i,"Open a source file in Quartus before loading QOL");
 /* Refuse different machine code instead of risking incorrect offsets. SHA256 is
    additionally checked by the Tcl loader before this DLL is loaded. */
 const unsigned char sig[]={0x48,0x8b,0x49,0x28,0x48,0x83,0xc1,0x10,0x4d,0x63,0xc9};
 if(memcmp(editor+0x5b170,sig,sizeof(sig)))return fail(i,"Unsupported Quartus editor build");
 get_app=*(void**)(editor+0x1be6a0);get_mgr=*(void**)(editor+0x1c0b90);get_frames=*(void**)(editor+0x1c0b88);destroy_string=*(void**)(editor+0x1bef58);
 HMODULE q=GetModuleHandleA("sys_qui.dll");get_filepath=(void*)GetProcAddress(q,"?get_qstring_filepath@QUI_FRAME_WND@@QEBA?AVQString@@XZ");get_filename=(void*)GetProcAddress(q,"?get_qstring_filename@QUI_FRAME_WND@@QEBA?AVQString@@XZ");
 deallocate=(void*)GetProcAddress(GetModuleHandleA("Qt6Core.dll"),"?deallocate@QArrayData@@SAXPEAU1@_J1@Z");if(!get_filepath||!deallocate)return fail(i,"Required Quartus Qt functions missing");
 HMODULE widgets=GetModuleHandleA("Qt6Widgets.dll");
 all_widgets=(void*)GetProcAddress(widgets,"?allWidgets@QApplication@@SA?AV?$QList@PEAVQWidget@@@@XZ");
 class_name=(void*)GetProcAddress(GetModuleHandleA("Qt6Core.dll"),"?className@QMetaObject@@QEBAPEBDXZ");
 object_name=(void*)GetProcAddress(GetModuleHandleA("Qt6Core.dll"),"?objectName@QObject@@QEBA?AVQString@@XZ");
 get_stylesheet=(void*)GetProcAddress(widgets,"?styleSheet@QWidget@@QEBA?AVQString@@XZ");
 set_updates=(void*)GetProcAddress(widgets,"?setUpdatesEnabled@QWidget@@QEAAX_N@Z");
 set_stylesheet=(void*)GetProcAddress(widgets,"?setStyleSheet@QWidget@@QEAAXAEBVQString@@@Z");
 if(!all_widgets||!class_name||!object_name||!set_stylesheet||!get_stylesheet||!set_updates)return fail(i,"Required Qt theme functions missing");
 cursor_pos=(void*)GetProcAddress(GetModuleHandleA("Qt6Gui.dll"),"?pos@QCursor@@SA?AVQPoint@@XZ");
 map_global=(void*)GetProcAddress(widgets,"?mapFromGlobal@QWidget@@QEBA?AVQPoint@@AEBV2@@Z");
 widget_at=(void*)GetProcAddress(widgets,"?widgetAt@QApplication@@SAPEAVQWidget@@AEBVQPoint@@@Z");
 viewport_of=(void*)GetProcAddress(widgets,"?viewport@QAbstractScrollArea@@QEBAPEAVQWidget@@XZ");
 active_window=(void*)GetProcAddress(widgets,"?activeWindow@QApplication@@SAPEAVQWidget@@XZ");
 window_of=(void*)GetProcAddress(widgets,"?window@QWidget@@QEBAPEAV1@XZ");
 parent_of=(void*)GetProcAddress(GetModuleHandleA("Qt6Core.dll"),"?parent@QObject@@QEBAPEAV1@XZ");
 string_from_utf8=*(void**)(editor+0x1bf070);
 tooltip_show=(void*)GetProcAddress(widgets,"?showText@QToolTip@@SAXAEBVQPoint@@AEBVQString@@PEAVQWidget@@AEBVQRect@@H@Z");
 tooltip_hide=(void*)GetProcAddress(widgets,"?hideText@QToolTip@@SAXXZ");
 if(!cursor_pos||!map_global||!widget_at||!viewport_of||!active_window||!window_of||!parent_of||!tooltip_show||!tooltip_hide)return fail(i,"Required Quartus hover functions missing");
 init_options();owner_thread=GetCurrentThreadId();Tcl_CreateObjCommand(i,"qol_native",command,NULL,NULL);return 0;
}
