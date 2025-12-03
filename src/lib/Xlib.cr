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
    type GdkPixbuf   = Void*
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

    # GObject
    fun g_signal_connect =g_signal_connect_data(instance : GObject*, detailed_signal : UInt8*,
                                c_handler : GCallback*,user : Void*) : UInt64
    fun g_idle_add(func : GSourceFunc, data : Void*) : UInt32
    fun g_thread_new(name : UInt8*, func : (-> Pointer(Void)), data : Void*) : Void*

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
    fun gtk2_about_logo=gtk_about_dialog_set_logo(dialog : GtkWidget, logo : GdkPixbuf*)
    fun gtk2_dialog_run=gtk_dialog_run(dialog : GtkWidget)
    fun gtk2_widget_destroy=gtk_widget_destroy(dialog : GtkWidget)
    fun gtk2_load_icon=gtk_icon_theme_load_icon( theme : Void*, icon_name : UInt8*,
                                    size : Int32, flags : Int32, error : Void**) : GdkPixbuf*
    fun gtk2_icon_theme_get_default=gtk_icon_theme_get_default() : Void*
    fun gtk2_quit=gtk_main_quit()
    fun gtk2_menu=gtk_menu_new() : GtkWidget
    fun gtk2_menu_item_label=gtk_menu_item_new_with_label(txt : UInt8*) : GtkWidget
    fun gtk2_menu_shell_append=gtk_menu_shell_append(menu_shell : GtkWidget, child : GtkWidget)
    fun gtk2_widget_show=gtk_widget_show_all(widget : GtkWidget)
    fun gtk2_menu_popup=gtk_menu_popup(menu : GtkWidget, parent_menu_shell : GtkWidget, parent_menu_item : GtkWidget,
                                func : GtkMenuPositionFunc, data : Void*, button : UInt32, activate_time : UInt32)
    ## X11
    # XEvent
    struct AnyEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
    end
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
    struct ButtonEvent
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
          button : UInt32
          same_screen : Bool
    end
    struct MotionEvent
          type : Int32 # of event
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
          is_hint : UInt8
          same_screen : Bool
    end
    struct CrossingEvent
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
          mode : Int32
          detail : Int32
          same_screen : Bool
          focus : Bool
          state : UInt32
    end
    struct FocusChangeEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
        	mode : Int32
          detail : Int32
    end
    struct ExposeEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          x, y : Int32
          width, height : Int32
          count : Int32
    end
    struct GraphicsExposeEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          drawable : Void*
          x, y : Int32
          width, height : Int32
          count : Int32
          major_code : Int32
          minor_code : Int32
    end
    struct NoExposeEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          drawable : Void*
          major_code : Int32
          minor_code : Int32
    end
    struct VisibilityEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          state : Int32
    end
    struct CreateWindowEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          parent : Window
          window : Window
          x, y : Int32
          width, height : Int32
          border_width : Int32
          override_redirect : Bool
    end
    struct DestroyWindowEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          event : Window
          window : Window
    end
    struct UnmapEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          event : Window
          window : Window
          from_configure : Bool
    end
    struct MapEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          event : Window
          window : Window
          override_redirect : Bool
    end
    struct MapRequestEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          parent : Window
          window : Window
    end
    struct ReparentEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          event : Window
          window : Window
          parent : Window
          x, y : Int32
          override_redirect : Bool
    end
    struct ConfigureEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          event : Window
          window : Window
          x, y : Int32
          width, height : Int32
          border_width : Int32
          above : Window
          override_redirect : Bool
    end
    struct GravityEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          event : Window
          window : Window
          x, y : Int32
    end
    struct ResizeRequestEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          width, height : Int32
    end
    struct ConfigureRequestEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          parent : Window
          window : Window
          x, y : Int32
          width, height : Int32
          border_width : Int32
          above : Window
          detail : Int32
          value_mask : UInt64
    end
    struct CirculateEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          parent : Window
          window : Window
          place : Int32
    end
    struct CirculateRequestEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          parent : Window
          window : Window
          place : Int32
    end
    struct PropertyEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          atom : Int32
          time : Void*
          state : Int32
    end
    struct SelectionClearEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          selection : Int32
          time : Void*
    end
    struct SelectionRequestEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          owner : Window
          requestor : Window
          selection : Void*
          target : Void*
          property : Void*
          time : Void*
    end
    struct SelectionEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          requestor : Window
          selection : Void*
          target : Void*
          property : Void*
          time : Void*
    end
    struct ColormapEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          colormap : Void*
          c_new : Bool
          state : Int32
    end
    union ClientMessageEvent_Data
          b : UInt8[20]
          s : Int16[10]
          l : Int64[5]
          ul : UInt64[5]
    end
    struct ClientMessageEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          message_type : Void*
          format : Int32
          data : ClientMessageEvent_Data
    end
    struct MappingEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          request : Int32
          first_keycode : Int32
          count : Int32
    end
    struct ErrorEvent
          type : Int32
          display : Display
          resourceid : UInt64
          serial : UInt64
          error_code : UInt8
          request_code : UInt8
          minor_code : UInt8
    end
    struct KeymapEvent
          type : Int32
          serial : UInt64
          send_event : Bool
          display : Display
          window : Window
          key_vector : UInt8[32];
    end
    struct GenericEvent
          type       : Int32
          serial     : UInt64
          send_event : Bool
          display    : Display
          extension  : Int32
          evtype     : Int32
    end
    struct GenericEventCookie
          type       : Int32
          serial     : UInt64
          send_event : Bool
          display    : Display
          extension  : Int32
          evtype     : Int32
          cookie     : UInt32
          data       : Void*
    end
        union XEvent
          type : Int32
          any : AnyEvent
          key : KeyEvent
          button : ButtonEvent
          motion : MotionEvent
          crossing : CrossingEvent
          focus : FocusChangeEvent
          expose : ExposeEvent
          graphicsexpose : GraphicsExposeEvent
          noexpose : NoExposeEvent
          visibility : VisibilityEvent
          createwindow : CreateWindowEvent
          destroywindow : DestroyWindowEvent
          unmap : UnmapEvent
          map : MapEvent
          maprequest : MapRequestEvent
          reparent : ReparentEvent
          configure : ConfigureEvent
          gravity : GravityEvent
          resizerequest : ResizeRequestEvent
          configurerequest : ConfigureRequestEvent
          circulate : CirculateEvent
          circulaterequest : CirculateRequestEvent
          property : PropertyEvent
          selectionclear : SelectionClearEvent
          selectionrequest : SelectionRequestEvent
          selection : SelectionEvent
          colormap : ColormapEvent
          client : ClientMessageEvent
          mapping : MappingEvent
          error : ErrorEvent
          keymap : KeymapEvent
          generic : GenericEvent
          cookie : GenericEventCookie
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
  class_property notifiX : LRoot::NotifyNotification* =notify_new("Volume","Welcome","audio-volume-medium")
  class_property update_scheduled =false

  {% for m in LRoot.methods %}
    def self.{{m.name}}(*args)
      LRoot.{{m.name}}(*args)
    end
  {% end %}
  def self.call(&)
   with self yield
  end
end