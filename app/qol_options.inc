/* Real AFCQ Options pages, pinned to gcl_afcq.dll from Quartus 24.1std 1077.
 * Only our own AFCQ_TREE_PAGE instances get a cloned virtual table. Existing
 * Quartus instances, executable pages, binaries and shared tables are untouched.
 */
enum {OPT_COMPLETION,OPT_FORMAT,OPT_DIAGNOSTICS,OPT_HOVER,OPT_COLORS,OPT_PINS,OPT_THEME,OPT_INDENT,OPT_COLUMNS,OPT_WARNINGS,OPT_DELAY,OPT_COUNT};
enum {THEME_COUNT=7};
static void (*qt_spin_ctor)(void*,void*);
static int (*qt_spin_value)(void*);
static void (*qt_spin_set)(void*,int);
static void (*qt_spin_range)(void*,int,int);
static void (*qt_combo_ctor)(void*,void*);
static void (*qt_combo_add)(void*,const QtString*,const void*);
static int (*qt_combo_index)(void*);
static void (*qt_combo_set)(void*,int);
static void (*qt_label_ctor)(void*,const QtString*,void*,unsigned);
static int (*qt_inherits)(void*,const char*);
static QtString*(*qt_title)(void*,QtString*);
static void (*qt_set_title)(void*,const QtString*);
static void*(*qt_layout)(void*);
static void (*qt_vbox_ctor)(void*,void*);
static void (*qt_group_ctor)(void*,const QtString*,void*);
static void (*qt_check_ctor)(void*,const QtString*,void*);
static void (*qt_layout_add)(void*,void*);
static void (*qt_box_stretch)(void*,int);
static void (*qt_set_checked)(void*,int);
static int (*qt_checked)(void*);
static void (*qt_enabled)(void*,int);
static void (*qt_size_policy)(void*,int,int);
static void (*qt_show)(void*);
static void (*qt_name)(void*,const QtString*);
static QtList*(*af_pages)(void*,QtList*);
static void*(*af_page)(void*,int);
static void*(*af_page_ui)(void*);
static void*(*af_item)(void*);
static QtString*(*qt_item_text)(void*,QtString*);
static void*(*qt_item_parent)(void*);
static void (*af_page_ctor)(void*,int,void*,unsigned);
static void (*af_page_title)(void*,const QtString*);
static void*(*af_add_page)(void*,void*,void*,int);
static void (*af_enable_apply)(void*);
static void (*af_changed)(void*);
static void* af_base_vtable;
typedef struct OptionSession {void*sheet;void*checks[OPT_COUNT];void*spins[OPT_COUNT];void*theme_combo;void*pages[6];void**tables[6];int baseline[OPT_COUNT];DWORD created_at;struct OptionSession*next;} OptionSession;
static OptionSession*option_sessions;
static int option_pending,option_values[OPT_COUNT],options_ready;
static int options_current[OPT_COUNT]={1,1,1,1,1,0,0,4,120,1,400},options_busy;
static UINT_PTR options_timer;
static const char*option_keys[]={"completion","format_on_save","diagnostics","hover","editor_colors","pin_planner_colors","theme","indentation_spaces","column_limit","extra_warnings","hover_delay"};
static int option_min(int k){return k==OPT_INDENT?1:k==OPT_COLUMNS?40:0;}
static int option_max(int k){return k==OPT_THEME?THEME_COUNT-1:k==OPT_INDENT?16:k==OPT_COLUMNS?500:k==OPT_DELAY?5000:1;}
static int qt_string_equals(QtString*s,const char*ascii){size_t n=strlen(ascii);if((size_t)s->size!=n)return 0;for(size_t k=0;k<n;k++)if(s->ptr[k]!=(unsigned char)ascii[k])return 0;return 1;}
static int qt_list_contains(QtList*l,void*w){for(intptr_t k=0;k<l->size;k++)if(l->ptr[k]==w)return 1;return 0;}
static void name_widget(void*w,const char*name){QtString s={0};string_from_utf8(&s,name);qt_name(w,&s);destroy_string(&s);}
static int option_value(OptionSession*s,int k){if(k==OPT_THEME)return s->theme_combo?qt_combo_index(s->theme_combo):s->baseline[k];if(s->spins[k])return qt_spin_value(s->spins[k]);return s->checks[k]?!!qt_checked(s->checks[k]):s->baseline[k];}
static int options_changed(OptionSession*s){for(int k=0;k<OPT_COUNT;k++)if(option_value(s,k)!=s->baseline[k])return 1;return 0;}
static OptionSession*session_for_page(void*p){for(OptionSession*s=option_sessions;s;s=s->next)for(int k=0;k<6;k++)if(s->pages[k]==p)return s;return NULL;}
static int option_page_changed(void*p){OptionSession*s=session_for_page(p);return s?options_changed(s):0;}
static void option_commit(void*p){OptionSession*s=session_for_page(p);if(!s||!options_changed(s))return;for(int k=0;k<OPT_COUNT;k++){option_values[k]=option_value(s,k);s->baseline[k]=option_values[k];options_current[k]=option_values[k];}option_pending=1;}
static int option_accept(void*p){option_commit(p);return 1;}
static void option_reject(void*p){OptionSession*s=session_for_page(p);if(s){for(int k=0;k<OPT_COUNT;k++){if(s->checks[k])qt_set_checked(s->checks[k],s->baseline[k]);if(s->spins[k])qt_spin_set(s->spins[k],s->baseline[k]);}if(s->theme_combo)qt_combo_set(s->theme_combo,s->baseline[OPT_THEME]);}}
static void*new_group(void*parent,const char*title){
 void*group=calloc(1,4096);void*layout=calloc(1,4096);if(!group||!layout){free(group);free(layout);return NULL;}
 QtString t={0};string_from_utf8(&t,title);qt_group_ctor(group,&t,parent);destroy_string(&t);qt_vbox_ctor(layout,group);
 qt_size_policy(group,5,4);
 void*outer=qt_layout(parent);if(outer)qt_layout_add(outer,group);qt_show(group);return group;
}
static int new_check(OptionSession*s,int k,void*group,const char*label){
 if(!group)return 0;
 void*c=calloc(1,4096);if(!c)return 0;
 QtString t={0};string_from_utf8(&t,label);qt_check_ctor(c,&t,group);destroy_string(&t);
 char name[128];snprintf(name,sizeof(name),"quartus_qol_%s",option_keys[k]);name_widget(c,name);
 qt_set_checked(c,s->baseline[k]);qt_layout_add(qt_layout(group),c);qt_show(c);s->checks[k]=c;return 1;
}
static int new_theme_combo(OptionSession*s,void*group){
 if(!group)return 0;
 void*label=calloc(1,4096);void*combo=calloc(1,4096);if(!label||!combo){free(label);free(combo);return 0;}
 QtString text={0};string_from_utf8(&text,"Editor color theme:");qt_label_ctor(label,&text,group,0);destroy_string(&text);
 qt_layout_add(qt_layout(group),label);qt_show(label);
 qt_combo_ctor(combo,group);name_widget(combo,"quartus_qol_theme");
 const char*names[]={"Quartus (light, default)","Quartus Dark (original QOL)","Catppuccin Frappe","Nord","Tokyo Night","Catppuccin Latte (light)","Tokyo Night Day (light)"};
 /* An all-zero QVariant is the Qt 6 invalid/default value. */
 uint64_t empty_variant[4]={0};
 for(int k=0;k<THEME_COUNT;k++){string_from_utf8(&text,names[k]);qt_combo_add(combo,&text,empty_variant);destroy_string(&text);}
 qt_combo_set(combo,s->baseline[OPT_THEME]);qt_layout_add(qt_layout(group),combo);qt_show(combo);s->theme_combo=combo;return 1;
}
static int new_spin(OptionSession*s,int k,void*group,const char*label){
 if(!group)return 0;
 void*l=calloc(1,4096);void*spin=calloc(1,4096);if(!l||!spin){free(l);free(spin);return 0;}
 QtString text={0};string_from_utf8(&text,label);qt_label_ctor(l,&text,group,0);destroy_string(&text);
 qt_layout_add(qt_layout(group),l);qt_show(l);qt_spin_ctor(spin,group);
 char name[128];snprintf(name,sizeof(name),"quartus_qol_%s",option_keys[k]);name_widget(spin,name);
 qt_spin_range(spin,option_min(k),option_max(k));qt_spin_set(spin,s->baseline[k]);
 qt_layout_add(qt_layout(group),spin);qt_show(spin);s->spins[k]=spin;return 1;
}
static void*new_option_page(OptionSession*s,int index,int id,const char*title,void*parent_page){
 /* AFCQ_TREE_PAGE is 0x40 bytes in the pinned build. Reserve extra constructor
    space for Qt objects; their own destructors use the common release UCRT. */
 void*p=calloc(1,4096);if(!p)return NULL;af_page_ctor(p,id,s->sheet,0);
 void**original=*(void***)p;if(original!=af_base_vtable){return NULL;}
 void**table=calloc(54,sizeof(void*));if(!table)return NULL;
 memcpy(table,original-1,54*sizeof(void*));s->tables[index]=table;s->pages[index]=p;
 table[1+46]=option_page_changed;table[1+48]=option_accept;
 table[1+49]=option_reject;table[1+50]=option_commit;*(void***)p=table+1;
 QtString t={0};string_from_utf8(&t,title);af_page_title(p,&t);
 void*ui=af_page_ui(p);qt_set_title(ui,&t);destroy_string(&t);
 const char*names[]={"quartus_qol_editor_page","quartus_qol_formatting_page","quartus_qol_diagnostics_page","quartus_qol_colors_page","quartus_qol_pin_planner_page","quartus_qol_completion_page"};name_widget(ui,names[index]);
 if(!qt_layout(ui)){void*layout=calloc(1,4096);if(layout)qt_vbox_ctor(layout,ui);}
 af_add_page(s->sheet,p,parent_page?af_item(parent_page):NULL,0);return ui;
}
static int attach_options(OptionSession*s,QtList*ws){
 void*editor_page=NULL,*colors_page=NULL,*pin_page=NULL,*completion_page=NULL;
 for(intptr_t k=0;k<ws->size;k++){
  void*p=ws->ptr[k];if(!qt_inherits(p,"AFCQ_TREE_PAGE")||!widget_belongs_to(p,s->sheet))continue;
  void*item=af_item(p);if(!item)continue;
  QtString title={0};qt_item_text(item,&title);
  if(qt_string_equals(&title,"Text Editor"))editor_page=p;
  if(qt_string_equals(&title,"Pin Planner"))pin_page=p;
  if(qt_string_equals(&title,"Autocomplete Text"))completion_page=p;
  if(qt_string_equals(&title,"Colors")){
   void*parent=qt_item_parent(item);if(parent){QtString owner={0};qt_item_text(parent,&owner);if(qt_string_equals(&owner,"Text Editor"))colors_page=p;destroy_string(&owner);}
  }
  destroy_string(&title);
 }
 if(s->checks[OPT_COMPLETION])return 1;
 if(!editor_page){new_option_page(s,0,0x514f4c00,"Text Editor",NULL);editor_page=s->pages[0];}
 if(!editor_page)return 0;
 void*editor_ui=af_page_ui(editor_page);
 if(editor_page==s->pages[0]&&!qt_layout(editor_ui)){void*layout=calloc(1,4096);if(layout)qt_vbox_ctor(layout,editor_ui);}
 if(!qt_layout(editor_ui))return 0;
 void*completion_ui=completion_page?af_page_ui(completion_page):new_option_page(s,5,0x514f4c05,"Autocomplete Text",editor_page);
 if(!completion_ui||!qt_layout(completion_ui))return 0;
 void*completion_group=new_group(completion_ui,"Code completion");
 new_check(s,OPT_COMPLETION,completion_group,"Show keyword and identifier suggestions while typing");
 if(!completion_page)qt_box_stretch(qt_layout(completion_ui),1);
 void*format=new_option_page(s,1,0x514f4c01,"Formatting",editor_page);
 void*diagnostics=new_option_page(s,2,0x514f4c02,"Diagnostics",editor_page);
 if(!format||!diagnostics)return 0;
 void*fl=qt_layout(format);if(!fl){fl=calloc(1,4096);qt_vbox_ctor(fl,format);}
 void*dl=qt_layout(diagnostics);if(!dl){dl=calloc(1,4096);qt_vbox_ctor(dl,diagnostics);}
 void*fg=new_group(format,"SystemVerilog and Verilog formatting");
 new_check(s,OPT_FORMAT,fg,"Format automatically when saving (Verible)");
 new_spin(s,OPT_INDENT,fg,"Indentation width (spaces):");
 new_spin(s,OPT_COLUMNS,fg,"Line length (columns):");
 void*dg=new_group(diagnostics,"SystemVerilog and Verilog diagnostics");
 new_check(s,OPT_DIAGNOSTICS,dg,"Check saved files and underline errors and warnings (slang)");
 new_check(s,OPT_HOVER,dg,"Show diagnostic details when hovering over underlined code");
 new_check(s,OPT_WARNINGS,dg,"Enable extra Slang warnings (-Wextra)");
 new_spin(s,OPT_DELAY,dg,"Hover delay (milliseconds):");
 qt_box_stretch(fl,1);qt_box_stretch(dl,1);
 void*colors=colors_page?af_page_ui(colors_page):new_option_page(s,3,0x514f4c03,"Colors",editor_page);
 if(colors&&qt_layout(colors)){
  void*cg=new_group(colors,"Syntax highlighting");
  new_check(s,OPT_COLORS,cg,"Use enhanced syntax colors and matching block colors");
  new_theme_combo(s,cg);
  if(!colors_page)qt_box_stretch(qt_layout(colors),1);
 }
 void*pins=pin_page?af_page_ui(pin_page):new_option_page(s,4,0x514f4c04,"Pin Planner",NULL);
 if(pins&&qt_layout(pins)){
  void*pg=new_group(pins,"Assignment table appearance");
  new_check(s,OPT_PINS,pg,"Use the editor theme for Pin Planner assignment rows");
  if(!pin_page)qt_box_stretch(qt_layout(pins),1);
 }
 return 1;
}
static int options_native_scan(QtList*ws){
 int attached=0;
 OptionSession**link=&option_sessions;while(*link){OptionSession*s=*link;if(!qt_list_contains(ws,s->sheet)){
   *link=s->next;for(int j=0;j<6;j++)free(s->tables[j]);free(s);continue;
  }link=&s->next;
 }
 for(intptr_t k=0;k<ws->size;k++){
  void*w=ws->ptr[k];if(!qt_inherits(w,"AFCQ_TREE_SHEET"))continue;
  QtString t={0};qt_title(w,&t);int is_options=qt_string_equals(&t,"Options");destroy_string(&t);if(!is_options)continue;
  OptionSession*s=option_sessions;while(s&&s->sheet!=w)s=s->next;
  if(!s){s=calloc(1,sizeof(*s));if(!s)continue;s->sheet=w;s->created_at=GetTickCount();memcpy(s->baseline,options_current,sizeof(options_current));s->next=option_sessions;option_sessions=s;}
  /* Quartus constructs context-dependent editor pages after the dialog shell.
     Wait for that initialization before deciding a fallback page is needed. */
  if((DWORD)(GetTickCount()-s->created_at)<900)continue;
  attached|=attach_options(s,ws);
  if(s->checks[OPT_HOVER]&&s->checks[OPT_DIAGNOSTICS])qt_enabled(s->checks[OPT_HOVER],qt_checked(s->checks[OPT_DIAGNOSTICS]));
  if(s->theme_combo&&s->checks[OPT_COLORS])qt_enabled(s->theme_combo,qt_checked(s->checks[OPT_COLORS]));
  if(options_changed(s)){af_enable_apply(w);for(int j=0;j<6;j++)if(s->pages[j])af_changed(s->pages[j]);}
 }
 return attached;
}
static void CALLBACK options_tick(HWND hwnd,UINT message,UINT_PTR timer,DWORD time){
 (void)hwnd;(void)message;(void)timer;(void)time;
 if(!options_ready||options_busy)return;
 options_busy=1;QtList ws={0};all_widgets(&ws);options_native_scan(&ws);free_list(&ws);options_busy=0;
}
static int options_command(Tcl_Interp*i,int ac,Tcl_Obj*const*av){
 if(!options_ready)return fail(i,"Native Options integration unavailable for this build");
 if(ac<3)return fail(i,"Usage: qol_native options probe|poll ?boolean-list?");
 const char*op=Tcl_GetStringFromObj(av[2],NULL);
 if(!strcmp(op,"stop")){if(options_timer)KillTimer(NULL,options_timer);options_timer=0;return 0;}
 QtList ws={0};all_widgets(&ws);Tcl_Obj*r=Tcl_NewListObj(0,NULL);
 if(!strcmp(op,"probe")){
  for(intptr_t k=0;k<ws.size;k++)if(qt_inherits(ws.ptr[k],"AFCQ_TREE_SHEET")){
   void*w=ws.ptr[k];QtString t={0};qt_title(w,&t);append(i,r,Tcl_NewUnicodeObj(t.ptr,(int)t.size));destroy_string(&t);
   for(intptr_t j=0;j<ws.size;j++){
    void*p=ws.ptr[j];if(!qt_inherits(p,"AFCQ_TREE_PAGE")||!widget_belongs_to(p,w))continue;
    int id=*(int*)((char*)p+0x28);void*item=af_item(p);if(!item)continue;
    QtString title={0};qt_item_text(item,&title);append(i,r,Tcl_NewWideIntObj(id));append(i,r,Tcl_NewUnicodeObj(title.ptr,(int)title.size));destroy_string(&title);
   }
  }
 }else if(!strcmp(op,"poll")&&ac==4){
  int count;Tcl_Obj**values;if(Tcl_ListObjGetElements(i,av[3],&count,&values)||count!=OPT_COUNT){free_list(&ws);return fail(i,"Expected eleven editor settings");}
  int current[OPT_COUNT];for(int k=0;k<OPT_COUNT;k++){int64_t v;if(Tcl_GetWideIntFromObj(i,values[k],&v)){free_list(&ws);return 1;}if(v<option_min(k)||v>option_max(k)){free_list(&ws);return fail(i,"Editor setting out of range");}current[k]=(int)v;}
  if(!option_pending)memcpy(options_current,current,sizeof(current));
  if(!options_timer)options_timer=SetTimer(NULL,0,300,options_tick);
  pair(i,r,"attached",Tcl_NewWideIntObj(options_native_scan(&ws)));
  if(option_pending){Tcl_Obj*flags=Tcl_NewListObj(0,NULL);for(int k=0;k<OPT_COUNT;k++)append(i,flags,Tcl_NewWideIntObj(option_values[k]));pair(i,r,"applied",flags);option_pending=0;}
 }else {free_list(&ws);return fail(i,"Unknown Options operation");}
 free_list(&ws);Tcl_SetObjResult(i,r);return 0;
}
static void init_options(void){
 HMODULE c=GetModuleHandleA("Qt6Core.dll"),w=GetModuleHandleA("Qt6Widgets.dll"),g=GetModuleHandleA("Qt6Gui.dll"),a=GetModuleHandleA("gcl_afcq.dll");if(!a)return;
#define OPT_BIND(module,var,name) var=(void*)GetProcAddress(module,name);if(!var)return
 OPT_BIND(c,qt_inherits,"?inherits@QObject@@QEBA_NPEBD@Z");
 OPT_BIND(c,qt_name,"?setObjectName@QObject@@QEAAXAEBVQString@@@Z");
 OPT_BIND(w,qt_title,"?windowTitle@QWidget@@QEBA?AVQString@@XZ");
 OPT_BIND(w,qt_set_title,"?setWindowTitle@QWidget@@QEAAXAEBVQString@@@Z");
 OPT_BIND(w,qt_layout,"?layout@QWidget@@QEBAPEAVQLayout@@XZ");
 OPT_BIND(w,qt_vbox_ctor,"??0QVBoxLayout@@QEAA@PEAVQWidget@@@Z");
 OPT_BIND(w,qt_group_ctor,"??0QGroupBox@@QEAA@AEBVQString@@PEAVQWidget@@@Z");
 OPT_BIND(w,qt_check_ctor,"??0QCheckBox@@QEAA@AEBVQString@@PEAVQWidget@@@Z");
 OPT_BIND(w,qt_spin_ctor,"??0QSpinBox@@QEAA@PEAVQWidget@@@Z");
 OPT_BIND(w,qt_spin_value,"?value@QSpinBox@@QEBAHXZ");
 OPT_BIND(w,qt_spin_set,"?setValue@QSpinBox@@QEAAXH@Z");
 OPT_BIND(w,qt_spin_range,"?setRange@QSpinBox@@QEAAXHH@Z");
 OPT_BIND(w,qt_combo_ctor,"??0QComboBox@@QEAA@PEAVQWidget@@@Z");
 OPT_BIND(w,qt_combo_add,"?addItem@QComboBox@@QEAAXAEBVQString@@AEBVQVariant@@@Z");
 OPT_BIND(w,qt_combo_index,"?currentIndex@QComboBox@@QEBAHXZ");
 OPT_BIND(w,qt_combo_set,"?setCurrentIndex@QComboBox@@QEAAXH@Z");
 OPT_BIND(w,qt_label_ctor,"??0QLabel@@QEAA@AEBVQString@@PEAVQWidget@@V?$QFlags@W4WindowType@Qt@@@@@Z");
 OPT_BIND(w,qt_layout_add,"?addWidget@QLayout@@QEAAXPEAVQWidget@@@Z");
 OPT_BIND(w,qt_box_stretch,"?addStretch@QBoxLayout@@QEAAXH@Z");
 OPT_BIND(w,qt_set_checked,"?setChecked@QAbstractButton@@QEAAX_N@Z");
 OPT_BIND(w,qt_checked,"?isChecked@QAbstractButton@@QEBA_NXZ");
 OPT_BIND(w,qt_enabled,"?setEnabled@QWidget@@QEAAX_N@Z");
 OPT_BIND(w,qt_size_policy,"?setSizePolicy@QWidget@@QEAAXW4Policy@QSizePolicy@@0@Z");
 OPT_BIND(w,qt_show,"?show@QWidget@@QEAAXXZ");
 OPT_BIND(a,af_pages,"?get_list@AFCQ_TREE_SHEET@@QEAA?AV?$QList@H@@XZ");
 OPT_BIND(a,af_page,"?get_page@AFCQ_TREE_SHEET@@QEAAPEAVAFCQ_TREE_PAGE@@H@Z");
 OPT_BIND(a,af_page_ui,"?get_ui_page_widget@AFCQ_TREE_PAGE@@QEAAPEAVQWidget@@XZ");
 OPT_BIND(a,af_item,"?get_item@AFCQ_TREE_PAGE@@QEAAPEAVQStandardItem@@XZ");
 OPT_BIND(g,qt_item_text,"?text@QStandardItem@@QEBA?AVQString@@XZ");
 OPT_BIND(g,qt_item_parent,"?parent@QStandardItem@@QEBAPEAV1@XZ");
 OPT_BIND(a,af_page_ctor,"??0AFCQ_TREE_PAGE@@QEAA@HPEAVQWidget@@V?$QFlags@W4WindowType@Qt@@@@@Z");
 OPT_BIND(a,af_page_title,"?set_ui_page_title@AFCQ_TREE_PAGE@@QEAAXAEBVQString@@@Z");
 OPT_BIND(a,af_add_page,"?add_page@AFCQ_TREE_SHEET@@QEAAPEAVQStandardItem@@PEAVAFCQ_TREE_PAGE@@PEAV2@_N@Z");
 OPT_BIND(a,af_enable_apply,"?enable_apply_button@AFCQ_TREE_SHEET@@UEAAXXZ");
 OPT_BIND(a,af_changed,"?changed@AFCQ_TREE_PAGE@@UEAAXXZ");
 OPT_BIND(a,af_base_vtable,"??_7AFCQ_TREE_PAGE@@6BQObject@@@");
 /* Verify the exact base class table before creating any custom instance. */
 void**v=af_base_vtable;
 if(v[46]!=(char*)a+0x15600||v[48]!=(char*)a+0xedd0||v[49]!=(char*)a+0xf160||v[50]!=(char*)a+0x15510)return;
 options_ready=1;
#undef OPT_BIND
}
