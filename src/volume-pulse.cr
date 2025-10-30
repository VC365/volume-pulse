require "file_utils"
require "./lib/Xlib"
require "option_parser"
require "colorize"


enum Middle_click
   False; Mixer; Mute;
   def self.puts(s : String)
    puts "middle_click_action: unknown config #{s}".colorize.yellow
    return Middle_click::False
   end
end

module ConfigVariables
  Version="0.2.9"
  class_property volume_increase = 5
  class_property max_volume = 120
  class_property middle_click_action = Middle_click::False
  class_property mixer = "pavucontrol"
  class_property use_notifications = false
  class_property use_shortcuts = true
  class_property use_arguments = true

  def self.update_config(key : String, value : String)
    case key
    when "volume_increase"
      self.volume_increase = value.to_i
    when "max_volume"
      self.max_volume = value.strip("%").to_i
    when "middle_click_action"
      self.middle_click_action = Middle_click.parse(value) rescue Middle_click.puts(value)
    when "mixer"
      self.mixer = value
    when "use_notifications"
      self.use_notifications = value == "true"
    when "use_shortcuts"
      self.use_shortcuts = value == "true"
    when "use_arguments"
      self.use_arguments = value == "true"
    else
      puts "Warning: unknown config key '#{key}'".colorize.yellow
    end
  end
end

module Volume
  extend self
  private def vol(get_sink : String,arg="")
    dood=Process.new("sh",["-c",%Q(pactl #{get_sink} @DEFAULT_SINK@ #{arg})],
        output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    none={ output:dood.output.gets_to_end, error:dood.error.gets_to_end, status:dood.wait}
    raise %Q(What??\n #{none[:error]}) unless none[:status].success?
    return none[:output].strip
  end
  def get_volume
    vol("get-sink-volume"," | grep -oP '\\d+%' | head -n 1").strip("%").to_i
  end
  def get_mute
    vol("get-sink-mute").includes?("yes") ?true : false
  end
  def volume_up
    vol("set-sink-volume","#{[get_volume + ConfigVariables.volume_increase, ConfigVariables.max_volume].min}%")
  end
  def volume_down
      vol("set-sink-volume","-#{ConfigVariables.volume_increase}%")
  end
  def volume_mute
    vol("set-sink-mute", "toggle")
  end
  # Status
  def show_notification(volume : Int)
    return unless ConfigVariables.use_notifications
    Xlib.call do
     if(Volume.get_mute)
       notify_update(notifiX,"Volume"," #{volume}%","audio-volume-muted")
     else
        case volume
          when 0
            notify_update(notifiX,"Volume"," #{volume}%","audio-volume-muted")
          when 1..30
            notify_update(notifiX,"Volume"," #{volume}%","audio-volume-low")
          when 31..70
            notify_update(notifiX,"Volume"," #{volume}%","audio-volume-medium")
          else
            notify_update(notifiX,"Volume"," #{volume}%","audio-volume-high")
        end
      end
      notify_timeout(notifiX,1000)
      notify_show(notifiX,nil)
    end
  end
  @@icon_status : Int32 -> Nil =->(volume : Int32){}
  def icon_statusX(&d : Int32 -> Nil)
  @@icon_status=d
  end
  def icon_status(volume : Int)
    @@icon_status.call(volume)
  end
  def update
    volume=Volume.get_volume
    icon_status(volume)
    show_notification(volume) unless ConfigVariables.use_notifications
  end
  def update_safe(loopX : Bool)
    Xlib.call do
        dood=->(data : Pointer(Void)){
            update
            update_scheduled=false
            0
        }
        if loopX
            unless update_scheduled
                update_scheduled = true
                g_idle_add(dood, nil)
            end
        else
            g_idle_add(dood, nil)
        end
    end
  end
  def mixer
    return unless File.exists?("/usr/bin/#{ConfigVariables.mixer}")
    dood=Process.new("#{ConfigVariables.mixer}",
         output: Process::Redirect::Pipe, error: Process::Redirect::Pipe)
    none={error:dood.error.gets_to_end, status:dood.wait}
    raise %Q(can not run mixer\n #{none[:error]}) unless none[:status].success?
  end
end

module Event
    extend self
    def keys
      Xlib.call do
        xInitThreads()
        dpy=xOpenDisplay(nil)
        unless dpy
          STDERR.puts("Cannot open display");return;end
        root=xRootWindow(dpy,0)

        xGrabKey(dpy,xKeysymToKeycode(dpy,X11::XF86XK_AudioLowerVolume),
                    X11::AnyModifier,root,1,X11::GrabModeAsync,X11::GrabModeAsync)
        xGrabKey(dpy,xKeysymToKeycode(dpy,X11::XF86XK_AudioRaiseVolume),
                    X11::AnyModifier,root,1,X11::GrabModeAsync,X11::GrabModeAsync)
        xGrabKey(dpy,xKeysymToKeycode(dpy,X11::XF86XK_AudioMute),
                    X11::AnyModifier,root,1,X11::GrabModeAsync,X11::GrabModeAsync)

        xSelectInput(dpy, root, X11::KeyPressMask)
        ev = uninitialized LRoot::XEvent
        loop do
            xNextEvent(dpy, pointerof(ev))
            if (ev.type == X11::KeyPress)
              keysym = xKeycodeToKeysym(dpy, ev.key.keycode,0)
                case keysym
                  when X11::XF86XK_AudioRaiseVolume
                    Volume.volume_up
                    Volume.update_safe(true)
                  when X11::XF86XK_AudioLowerVolume
                    Volume.volume_down
                    Volume.update_safe(true)
                  when X11::XF86XK_AudioMute
                    Volume.volume_mute
                    Volume.update_safe(false)
                end
            end
        end
      end
    end
    def scroll
        ->(icon : LRoot::GtkStatusIcon, event : Pointer(Void), user_data : LRoot::GPointer) {
          e = event.as(LRoot::GdkEventScroll*)
          case e.value.direction
            when LRoot::GdkScrollDirection::UP # GDK_SCROLL_UP
            Volume.volume_down
            Volume.update_safe(true)
          when LRoot::GdkScrollDirection::DOWN # GDK_SCROLL_DOWN
            Volume.volume_up
            Volume.update_safe(true)
          end
          1
        }.pointer
    end
    def button
        ->(icon : LRoot::GtkStatusIcon, event : Pointer(Void), user_data : LRoot::GPointer) {
          e = event.as(LRoot::GdkEventButton*)
          case e.value.button
          when 1 # Left Click
            Volume.volume_mute
            Volume.update_safe(false)
          when 2 # Midden Click
            case ConfigVariables.middle_click_action
                when Middle_click::Mixer
                    Volume.mixer
                when Middle_click::Mute
                    Volume.volume_mute
            end
          end
          0
        }.pointer
    end
    private def pid;return "/tmp/volume-pulse.pid";end
    def signal_root
        File.write(pid, "#{Process.pid}")
        Signal::USR1.trap { Volume.update_safe(true) }
        sleep
    end
    def signal_update
        return unless File.exists?(pid)
        Process.signal(Signal::USR1,File.read(pid).to_i)
    end
    def prevent_double_run
        return unless File.exists?(pid)
        return unless Process.exists?(File.read(pid).to_i)
        puts "volume-pulse already runned!".colorize.yellow
        exit 1
    end
end

module GUI
    extend self
    private def panel(item : LRoot::GtkMenuItem, data : LRoot::GPointer)
        Xlib.call do
            about = gtk2_about()
            logo = gtk2_load_icon(gtk2_icon_theme_get_default(), "audio-volume-high", 48, 0, nil)
            gtk2_about_pname((about), "Volume Pulse")
            gtk2_about_version(about, ConfigVariables::Version)
            gtk2_about_comments(about, "      Volume control for your system tray.      ")
            gtk2_about_website(about, "https://vc-365.ir/volume-pulse")
            gtk2_about_weblabel(about, "Website")
            gtk2_about_copyright(about, "Proprietary. All rights reserved.")
            gtk2_about_logo(about, logo) if logo

            gtk2_dialog_run(about)
            gtk2_widget_destroy(about)
        end
    end
    private def menuX(icon : LRoot::GtkStatusIcon,button : UInt32,activate_time : UInt32, user_data : LRoot::GPointer)
       Xlib.call do
        menu = gtk2_menu()
        mixer = gtk2_menu_item_label("Open Mixer")
        g_signal_connect(mixer.as(LRoot::GObject*),"activate",->(item : LRoot::GtkMenuItem, data : LRoot::GPointer){Volume.mixer}.pointer.as(LRoot::GCallback*),nil)
        about = gtk2_menu_item_label("About")
        g_signal_connect(about.as(LRoot::GObject*),"activate",->(item : LRoot::GtkMenuItem, data : LRoot::GPointer){panel(item,data)}.pointer.as(LRoot::GCallback*),nil)
        quit = gtk2_menu_item_label("Quit")
        g_signal_connect(quit.as(LRoot::GObject*),"activate",->{LRoot.gtk2_quit()}.pointer.as(LRoot::GCallback*),nil)

        gtk2_menu_shell_append(menu, mixer)
        gtk2_menu_shell_append(menu, about)
        gtk2_menu_shell_append(menu, quit)

        gtk2_widget_show(menu)
        gtk2_menu_popup(menu, nil, nil, nil, nil, button, activate_time);
       end
    end
    def menu
        ->(icon : LRoot::GtkStatusIcon,button : UInt32,activate_time : UInt32, user_data : LRoot::GPointer){
            menuX(icon, button, activate_time, user_data)
        }.pointer
    end
end

def read_config
    home = ENV["HOME"]? || raise "Home not found??"
    config_dir=%Q(#{home}/.config/volume-pulse)
    config_file="#{config_dir}/config.conf"

    FileUtils.mkdir_p(config_dir) unless Dir.exists?(config_dir)
    File.write(config_file, <<-CONF
    volume_increase = 5
    max_volume = 200%

    # 'false', 'mixer', 'mute'
    middle_click_action = mixer

    mixer = pavucontrol

    use_notifications = false

    use_shortcuts = true

    use_arguments = true
    CONF
    ) unless File.exists?(config_file)

    # Initialize
    File.each_line(config_file) do |line|
        line=line.strip
        next if line.blank? || line.starts_with?("#")
        key,value=line.gsub(" ","").split("=")
        ConfigVariables.update_config(key,value)
    end
end

def parse_arguments
  OptionParser.parse do |arg|
    arg.banner="Usage: volume-pulse [-h --help] [-m] [-u] [-d] [-s] [-v]"
    arg.on("-m","Toggle mute") do
      Volume.volume_mute
      Event.signal_update
      exit 0
    end
    arg.on("-u","Increase volume") do
      Volume.volume_up
      Event.signal_update
      exit 0
    end
    arg.on("-d","Decrease volume") do
      Volume.volume_down
      Event.signal_update
      exit 0
    end
    arg.on("-s","Show volume level") do
        puts "#{Volume.get_volume}%";exit 0;end
    arg.on("-v","Version") do
        puts "Volume Pulse #{ConfigVariables::Version}";exit 0;end
    arg.on("-h","--help","Show help message") do
        puts arg;exit 0;end
    arg.separator("\t\t config path:  .config/volume-pulse/config.conf".colorize.yellow)

    arg.invalid_option do |val|
        STDERR.puts "ERROR: #{val} is not a valid option."
        STDERR.puts arg
        exit(1)
    end
  end
end

# Main
read_config
parse_arguments
Event.prevent_double_run
Xlib.call do
    notify("Volume Pulse") if ConfigVariables.use_notifications
    fcInit()
    gtk2_init(nil,nil)
    icon_tray : LRoot::GtkStatusIcon=gtk2_status_new()
    Volume.icon_statusX do |volume|
        Xlib.call do
          if (Volume.get_mute)
            gtk2_status_icon_tooltip_text(icon_tray,"Volume: Muted")
            gtk2_status_set_icon_name(icon_tray,"audio-volume-muted")
          else
            gtk2_status_icon_tooltip_text(icon_tray,"Volume: #{volume}")
            case volume
              when 0
                gtk2_status_set_icon_name(icon_tray,"audio-volume-muted")
              when 1..30
                gtk2_status_set_icon_name(icon_tray,"audio-volume-low")
              when 31..70
                gtk2_status_set_icon_name(icon_tray,"audio-volume-medium")
              else
                gtk2_status_set_icon_name(icon_tray,"audio-volume-high")
            end
          end
        end
    end
    Volume.update
    g_signal_connect(icon_tray.as(LRoot::GObject*),"scroll-event",Event.scroll.as(LRoot::GCallback*),nil)
    g_signal_connect(icon_tray.as(LRoot::GObject*),"button-press-event",Event.button.as(LRoot::GCallback*),nil)
    g_signal_connect(icon_tray.as(LRoot::GObject*),"popup-menu",GUI.menu.as(LRoot::GCallback*),nil)

    if ConfigVariables.use_arguments
        Fiber::ExecutionContext::Isolated.new("GTK") do
            LRoot.gtk2_main()
        end
    else
        gtk2_main()
    end
    notify_uninit() if ConfigVariables.use_notifications
end
Fiber::ExecutionContext::Isolated.new("X11") do
    Event.keys
end if ConfigVariables.use_shortcuts
Event.signal_root if ConfigVariables.use_arguments