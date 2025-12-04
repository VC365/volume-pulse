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
    Version="0.3.1"
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
    def icon_status(volume : Int)
        Xlib.call do
            if (Volume.get_mute)
                gtk2_status_icon_tooltip_text(GUI.icon_tray,"Volume: Muted")
                gtk2_status_set_icon_name(GUI.icon_tray,"audio-volume-muted")
            else
                gtk2_status_icon_tooltip_text(GUI.icon_tray,"Volume: #{volume}")
                case volume
                when 0
                    gtk2_status_set_icon_name(GUI.icon_tray,"audio-volume-muted")
                when 1..30
                    gtk2_status_set_icon_name(GUI.icon_tray,"audio-volume-low")
                when 31..70
                    gtk2_status_set_icon_name(GUI.icon_tray,"audio-volume-medium")
                else
                    gtk2_status_set_icon_name(GUI.icon_tray,"audio-volume-high")
                end
            end
        end
    end
    def update
        volume=Volume.get_volume
        icon_status(volume)
        show_notification(volume) unless ConfigVariables.use_notifications
    end
    def update_safe(loopX : Bool)
        Xlib.call do
            dood=->{
                update
                update_scheduled=false
                0
            }.pointer.as(VC365::GFunc)
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
            ev = uninitialized VC365::XEvent
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
        ->(icon : VC365::GtkStatusIcon, event : Pointer(Void), user_data : VC365::GPointer) {
            e = event.as(VC365::GdkEventScroll*).value
            case e.direction
                when VC365::GdkScrollDirection::UP
                Volume.volume_down
                Volume.update_safe(true)
            when VC365::GdkScrollDirection::DOWN
                Volume.volume_up
                Volume.update_safe(true)
            end
            1
        }.pointer.as(VC365::GFunc)
    end
    def button
        ->(icon : VC365::GtkStatusIcon, event : Pointer(Void), user_data : VC365::GPointer) {
            e = event.as(VC365::GdkEventButton*).value
            case e.button
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
        }.pointer.as(VC365::GFunc)
    end
    private def pid;return "/tmp/volume-pulse.pid";end
    def signal_root
        File.write(pid, "#{Process.pid}")
        Signal::USR1.trap { Volume.update_safe(true) }
        sleep
    end
    def signal_update
        return unless File.exists?(pid)
        pidX=File.read(pid).to_i
        Process.exists?(pidX) ? Process.signal(Signal::USR1,pidX) :
            puts "Warning: volume-pulse is not running!".colorize.yellow
    end
    def prevent_double_run
        return unless File.exists?(pid)
        return unless Process.exists?(File.read(pid).to_i)
        puts "volume-pulse is already running!".colorize.yellow
        exit 1
    end
end

module GUI
    class_property! icon_tray : VC365::GtkStatusIcon
    private def self.panel(item : VC365::GtkMenuItem, data : VC365::GPointer)
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
    private def self.menuX(icon : VC365::GtkStatusIcon,button : UInt32,activate_time : UInt32, user_data : VC365::GPointer)
        Xlib.call do
            menu = gtk2_menu()
            mixer = gtk2_menu_item_label("Open Mixer")
            g_signal_connect(mixer.as(VC365::GObject),"activate",
                ->(item : VC365::GtkMenuItem, data : VC365::GPointer){Volume.mixer}.pointer.as(VC365::GFunc),nil)
            about = gtk2_menu_item_label("About")
            g_signal_connect(about.as(VC365::GObject),"activate",
                ->(item : VC365::GtkMenuItem, data : VC365::GPointer){panel(item,data)}.pointer.as(VC365::GFunc),nil)
            quit = gtk2_menu_item_label("Quit")
            g_signal_connect(quit.as(VC365::GObject),"activate",
                ->{VC365.gtk2_quit()}.pointer.as(VC365::GFunc),nil)

            gtk2_menu_shell_append(menu, mixer)
            gtk2_menu_shell_append(menu, about)
            gtk2_menu_shell_append(menu, quit)

            gtk2_widget_show(menu)
            gtk2_menu_popup(menu, nil, nil, nil, nil, button, activate_time);
        end
    end
    def self.menu
        ->(icon : VC365::GtkStatusIcon,button : UInt32,activate_time : UInt32, user_data : VC365::GPointer){
            menuX(icon, button, activate_time, user_data)
        }.pointer.as(VC365::GFunc)
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
    if ConfigVariables.use_notifications
        notify("Volume Pulse")
        Xlib.notifiX=notify_new("Volume","Welcome","audio-volume-medium")
    end
    fcInit()
    gtk2_init(nil,nil)
    GUI.icon_tray=gtk2_status_new()
    Volume.update
    g_signal_connect(GUI.icon_tray.as(VC365::GObject),"scroll-event",Event.scroll,nil)
    g_signal_connect(GUI.icon_tray.as(VC365::GObject),"button-press-event",Event.button,nil)
    g_signal_connect(GUI.icon_tray.as(VC365::GObject),"popup-menu",GUI.menu,nil)

    unless !ConfigVariables.use_arguments && !ConfigVariables.use_shortcuts
        Fiber::ExecutionContext::Isolated.new("GTK") do
            VC365.gtk2_main()
        end
        Fiber::ExecutionContext::Isolated.new("X11") do
            Event.keys
        end if ConfigVariables.use_shortcuts
        ConfigVariables.use_arguments ? Event.signal_root : sleep
    else
        gtk2_main()
    end
    notify_uninit() if ConfigVariables.use_notifications
end