# Palette names/order are shared with the native Colors dropdown.
# Theme names refer to color palettes, not embedded editors or UI skins.
namespace eval ::quartus_qol {
 variable theme_keys {quartus quartus_dark catppuccin_frappe nord tokyo_night catppuccin_latte tokyo_day}
 variable palettes [dict create]
}
proc ::quartus_qol::define_palette {name surfaces roles depths} {
 variable palettes
 set p [dict create]
 foreach key {base text gutter line selection comment guide} value $surfaces {dict set p $key $value}
 foreach key {string number keyword type module function port instance constant preprocessor operator label escape unmatched} value $roles {dict set p $key $value}
 dict set p depths $depths
 dict set p gutter_text [expr {$name eq {quartus} ? {#606060} : [dict get $p comment]}]
 dict set palettes $name $p
}
::quartus_qol::define_palette quartus {
 #ffffff #000000 #e8e8de #f3f3f3 #b8d5f1 #008000 #cccccc
} {
 #008000 #ff4000 #0000ff #000080 #805500 #795e26 #004080 #000000
 #a31515 #800080 #404040 #005a80 #a05000 #c00000
} {#a31515 #946500 #008000 #008080 #0000cc #800080}
::quartus_qol::define_palette quartus_dark {
 #2d2d2d #dddddd #272727 #3c3c3c #4b5660 #8f9b8d #626262
} {
 #aabf93 #d4ae7b #92b7d0 #9bbec4 #cebd8c #c9bd91 #8db6d1 #dddddd
 #c6ab89 #b49cc6 #a9b8be #bac5cc #d0b58c #e28b8b
} {#d99886 #c7ad75 #a9bc83 #7eb6b1 #8eafd0 #b69aca}
::quartus_qol::define_palette catppuccin_frappe {
 #303446 #c6d0f5 #292c3c #414559 #51576d #a5adce #626880
} {
 #a6d189 #ef9f76 #ca9ee6 #e5c890 #e5c890 #8caaee #99d1db #c6d0f5
 #ef9f76 #ca9ee6 #81c8be #babbf1 #e5c890 #e78284
} {#e78284 #ef9f76 #e5c890 #a6d189 #99d1db #ca9ee6}
::quartus_qol::define_palette nord {
 #2e3440 #d8dee9 #3b4252 #3b4252 #434c5e #8c97ac #4c566a
} {
 #a3be8c #b48ead #81a1c1 #8fbcbb #8fbcbb #88c0d0 #88c0d0 #d8dee9
 #b48ead #5e81ac #81a1c1 #d8dee9 #ebcb8b #bf616a
} {#bf616a #d08770 #ebcb8b #a3be8c #88c0d0 #b48ead}
::quartus_qol::define_palette tokyo_night {
 #1a1b26 #c0caf5 #16161e #24283b #394b70 #858db5 #414868
} {
 #9ece6a #ff9e64 #bb9af7 #7dcfff #e0af68 #7aa2f7 #73daca #c0caf5
 #ff9e64 #9d7cd8 #89ddff #a9b1d6 #e0af68 #f7768e
} {#f7768e #ff9e64 #e0af68 #9ece6a #7dcfff #bb9af7}
::quartus_qol::define_palette catppuccin_latte {
 #eff1f5 #4c4f69 #e6e9ef #e6e9ef #ccd0da #6c6f85 #acb0be
} {
 #40a02b #fe640b #8839ef #179299 #946515 #1e66f5 #007b91 #4c4f69
 #b34700 #8839ef #179299 #4c4f69 #946515 #d20f39
} {#d20f39 #b34700 #946515 #327d22 #007b91 #8839ef}
::quartus_qol::define_palette tokyo_day {
 #e1e2e7 #3760bf #d0d5e3 #d5d9e6 #b7c1e3 #6172b0 #a8aecb
} {
 #587539 #b15c00 #9854f1 #007197 #8c6c3e #2e7de9 #188092 #3760bf
 #b15c00 #7847bd #007197 #6172b0 #8c6c3e #f52a65
} {#c52855 #b15c00 #8c6c3e #587539 #007197 #7847bd}
proc ::quartus_qol::current_palette {} {
 variable config; variable palettes
 return [dict get $palettes [dict get $config theme]]
}
