@[Link("gtk-x11-2.0")]
@[Link("gobject-2.0")]
@[Link("glib-2.0")]
@[Link("X11")]
@[Link("notify")]
@[Link("fontconfig")]
lib VC365
    # Types
    type NotifyNotification = Void*
    type GPointer = Void*
    type GtkWidget = Void*
    type GtkStatusIcon = Void*
    type GtkMenuItem = Void*
    type GtkMenuShell = Void*
    type GObject   = Void*
    type GFunc   = Void*
    type Display = Void*
    alias Window = UInt64
    alias KeySym = UInt64
    alias GtkMenuPositionFunc = (Void*, Int32*, Int32*, Void*) -> Void

    # Notify
    fun notify=notify_init(app_name : UInt8*)
    fun notify_uninit()
    fun notify_new=notify_notification_new(summray : UInt8*,msg : UInt8*,icon : UInt8*) : NotifyNotification
    fun notify_timeout=notify_notification_set_timeout(summray : NotifyNotification,timeout : Int32)
    fun notify_show=notify_notification_show(notification : NotifyNotification,gerror : Void*)
    fun notify_close=notify_notification_close(notification : NotifyNotification,gerror : Void*)
    fun notify_update=notify_notification_update(notification : NotifyNotification,summray : UInt8*,msg : UInt8*,icon : UInt8*)

    # GLib
    fun g_signal_connect =g_signal_connect_data(instance : GObject, detailed_signal : UInt8*,
                                c_handler : GFunc,user : Void*) : UInt64
    fun g_idle_add(func : GFunc, data : Void*) : UInt32

    # Gdk
    enum GdkEventType : Int32
        NOTHING = -1
        DELETE = 0
        DESTROY = 1
        EXPOSE = 2
        MOTION_NOTIFY = 3
        BUTTON_PRESS = 4
        BUTTON_RELEASE = 5
        SCROLL = 31
    end
    enum GdkScrollDirection : Int32
        UP = 0
        DOWN = 1
        LEFT = 2
        RIGHT = 3
        SMOOTH = 4
    end
    struct GdkEventScroll
        type : GdkEventType
        window : Void*
        send_event : Int8
        time : UInt32
        x : Float64
        y : Float64
        state : UInt32
        direction : GdkScrollDirection
        device : Void*
        x_root : Float64
        y_root : Float64
    end
    struct GdkEventButton
      type : GdkEventType
      window : Window
      send_event : UInt8
      time : UInt32
      x : Float64
      y : Float64
      axes : Pointer(Float64)
      state : UInt32
      button : UInt32
      device : Pointer(Void)
      x_root : Float64
      y_root : Float64
    end
    struct GdkEvent
      type : GdkEventType
      button : GdkEventButton
      scroll : GdkEventScroll
    end



    # Gtk2
    fun gtk2_init=gtk_init(argc : Void*, argv : Void*)
    fun gtk2_main=gtk_main()
    fun gtk2_status_new=gtk_status_icon_new() : GtkStatusIcon
    fun gtk2_status_new_icon_name=gtk_status_icon_new_from_icon_name(name : UInt8*) : GtkStatusIcon
    fun gtk2_status_set_icon_name=gtk_status_icon_set_from_icon_name(status_icon : GtkStatusIcon,name : UInt8*)
    fun gtk2_status_icon_tooltip_text=gtk_status_icon_set_tooltip_text(icon_tray : GtkStatusIcon,msg : UInt8*)
    fun gtk2_about=gtk_about_dialog_new() : GtkWidget
    fun gtk2_about_pname=gtk_about_dialog_set_program_name(dialog : GtkWidget, name : UInt8*)
    fun gtk2_about_version=gtk_about_dialog_set_version(dialog : GtkWidget, version : UInt8*)
    fun gtk2_about_comments=gtk_about_dialog_set_comments(dialog : GtkWidget, comments : UInt8*)
    fun gtk2_about_website=gtk_about_dialog_set_website(dialog : GtkWidget, website : UInt8*)
    fun gtk2_about_weblabel=gtk_about_dialog_set_website_label(dialog : GtkWidget, website_label : UInt8*)
    fun gtk2_about_copyright=gtk_about_dialog_set_copyright(dialog : GtkWidget, copyright : UInt8*)
    fun gtk2_about_logo_icon=gtk_about_dialog_set_logo_icon_name(dialog : GtkWidget, logo : UInt8*)
    fun gtk2_about_authors=gtk_about_dialog_set_authors(dialog : GtkWidget, authors : UInt8**)
    fun gtk2_dialog_run=gtk_dialog_run(dialog : GtkWidget)
    fun gtk2_widget_destroy=gtk_widget_destroy(dialog : GtkWidget)
    fun gtk2_quit=gtk_main_quit()
    fun gtk2_menu_new=gtk_menu_new() : GtkWidget
    fun gtk2_menu_item_label=gtk_menu_item_new_with_label(txt : UInt8*) : GtkWidget
    fun gtk2_menu_shell_append=gtk_menu_shell_append(menu_shell : GtkWidget, child : GtkWidget)
    fun gtk2_widget_show=gtk_widget_show_all(widget : GtkWidget)
    fun gtk2_menu_popup=gtk_menu_popup(menu : GtkWidget, parent_menu_shell : GtkWidget, parent_menu_item : GtkWidget,
                                func : GtkMenuPositionFunc, data : Void*, button : UInt32, activate_time : UInt32)
    ## X11
    # XEvent
    struct KeyEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          root : Window
          subwindow : Window
          time : Void*
          x, y : Int32
          x_root, y_root : Int32
          state : UInt32
          keycode : UInt32
          same_screen : Bool
    end
    union XEvent
          type : Int32
          any : Void*
          key : KeyEvent
          button : Void*
          motion : Void*
          crossing : Void*
          focus : Void*
          expose : Void*
          graphicsexpose : Void*
          noexpose : Void*
          visibility : Void*
          createwindow : Void*
          destroywindow : Void*
          unmap : Void*
          map : Void*
          maprequest : Void*
          reparent : Void*
          configure : Void*
          gravity : Void*
          resizerequest : Void*
          configurerequest : Void*
          circulate : Void*
          circulaterequest : Void*
          property : Void*
          selectionclear : Void*
          selectionrequest : Void*
          selection : Void*
          colormap : Void*
          client : Void*
          mapping : Void*
          error : Void*
          keymap : Void*
          generic : Void*
          cookie : Void*
          pad : Int64[24];
    end
    # end

    fun xInitThreads=XInitThreads()

    fun xOpenDisplay=XOpenDisplay(display_name : UInt8*) : Display
    fun xRootWindow=XRootWindow(display : Display, screen_number : Int32) : Window
    fun xGrabKey=XGrabKey(display : Display, keycode : Int32, modifiers : UInt32, grab_window : Window,
                 owner_events : Int32, pointer_mode : Int32, keyboard_mode : Int32) : Int32
    fun xSelectInput=XSelectInput(display : Display, window : Window, event_mask : Int64) : Int32
    fun xNextEvent=XNextEvent(display : Display, event_return : XEvent*) : Int32
    fun xKeysymToKeycode=XKeysymToKeycode(display : Display, keycode : Int32) : KeySym
    fun xKeycodeToKeysym=XKeycodeToKeysym(display : Display, keycode : Int32, index : Int32) : KeySym

    # Other
    fun fcInit=FcInit()
end

module X11
AnyModifier= (1<<15)
XF86XK_AudioLowerVolume=(0x1008ff11_i64)
XF86XK_AudioRaiseVolume=(0x1008ff13_i64)
XF86XK_AudioMute=(0x1008ff12_i64)
KeyPressMask= (1_i64 << 0)
GrabModeAsync = 1
KeyPress=2
end

module Xlib
    class_property! notifiX : VC365::NotifyNotification
    class_property update_scheduled =false

    def self.g_signal(ele : _,sig : String, block : Proc)
        VC365.g_signal_connect(ele.as(VC365::GObject),sig,block.pointer.as(VC365::GFunc),nil)
    end

    {% for m in VC365.methods %}
        def self.{{m.name}}(*args)
            VC365.{{m.name}}(*args)
        end
    {% end %}
    def self.call(&)
        with self yield
    end
end