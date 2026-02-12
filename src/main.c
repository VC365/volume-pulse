#include <gtk/gtk.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <X11/Xlib.h>
#include <X11/XF86keysym.h>
#include <libnotify/notify.h>
#include <ctype.h>
#include <fontconfig/fontconfig.h>

#define MAX_LEN 100
#define MAX_VOLUME_LEN 10

//#For Config
char volume_adjustment[MAX_LEN] = "5";
char max_volume[MAX_LEN] = "100%";
char middle_click_action[MAX_LEN] = "false"; // "false", "mixer", "mute"
char mixer[MAX_LEN] = "pavucontrol";
int use_notifications = 0;
int use_shortcuts = 1;
int use_arguments = 1;
const gchar* version = "0.3.2";

//#For Volume Status
char current_volume[MAX_VOLUME_LEN];

//#For Notification
NotifyNotification* current_notification = NULL;

//#For Icon_Tray
GtkStatusIcon* tray_icon;

////Config File
void strtrim(char* str)
{
    char* comment_start = strchr(str, '#');
    if (comment_start != NULL)
        *comment_start = '\0';

    while (isspace((unsigned char)*str)) str++;

    if (*str == 0) return;

    char* end = str + strlen(str) - 1;
    while (end > str && isspace((unsigned char)*end)) end--;

    *(end + 1) = 0;
}

void read_config()
{
    const char* home = getenv("HOME");
    if (!home)
    {
        fprintf(stderr, "Could not find HOME env.\n");
        return;
    }

    char dir_path[256];
    char config_path[512];
    snprintf(dir_path, sizeof(dir_path), "%s/.config/volume-pulse", home);
    snprintf(config_path, sizeof(config_path), "%s/config.conf", dir_path);

    if (access(config_path, F_OK) != 0)
    {
        mkdir(dir_path, 0700);

        FILE* fp = fopen(config_path, "w");
        if (fp)
        {
            fputs(
                "volume_increase = 5\n"
                "max_volume = 200%\n\n"
                "# 'false', 'mixer', 'mute'\n"
                "middle_click_action = mixer\n\n"
                "mixer = pavucontrol\n\n"
                "use_notifications = false\n\n"
                "use_shortcuts = true\n\n"
                "use_arguments = true\n\n",
                fp
            );
            fclose(fp);
        }
        else
        {
            perror("Failed to create config file");
            return;
        }
    }

    FILE* file = fopen(config_path, "r");
    if (!file)
    {
        perror("Error opening config file");
        return;
    }

    char line[MAX_LEN];
    while (fgets(line, sizeof(line), file))
    {
        if (line[0] == '#' || line[0] == '\n')
            continue;

        char key[MAX_LEN], value[MAX_LEN];
        if (sscanf(line, " %99[^= ]%*[ ]=%*[ ]%99[^\n]", key, value) != 2)
            continue;

        strtrim(key);
        strtrim(value);
        if (strcmp(key, "volume_increase") == 0)
            strncpy(volume_adjustment, value, MAX_LEN);
        else if (strcmp(key, "max_volume") == 0)
            strncpy(max_volume, value, MAX_LEN);
        else if (strcmp(key, "middle_click_action") == 0)
            strncpy(middle_click_action, value, MAX_LEN);
        else if (strcmp(key, "mixer") == 0)
            strncpy(mixer, value, MAX_LEN);
        else if (strcmp(key, "use_notifications") == 0)
            use_notifications = (strcasecmp(value, "true") == 0);
        else if (strcmp(key, "use_shortcuts") == 0)
            use_shortcuts = (strcasecmp(value, "true") == 0);
        else if (strcmp(key, "use_arguments") == 0)
            use_arguments = (strcasecmp(value, "true") == 0);
    }
    fclose(file);
}

//end-------------------

//Volume GG
void run_pactl(const char* arg1, const char* arg2)
{
    pid_t pid = fork();
    if (pid == 0)
    {
        execlp("pactl", "pactl", arg1, "@DEFAULT_SINK@", arg2, (char*)NULL);
        _exit(EXIT_FAILURE);
    }
}

void run_mixer_app()
{
    pid_t pid = fork();
    if (pid == 0)
    {
        execlp(mixer, mixer, (char*)NULL);
        _exit(EXIT_FAILURE);
    }
}

const gchar* get_volume()
{
    static gchar volume[MAX_VOLUME_LEN];
    FILE* fp = popen("pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+%' | head -n 1", "r");

    if (fp != NULL)
    {
        if (fgets(volume, MAX_VOLUME_LEN, fp) != NULL)
        {
            fclose(fp);
            return volume;
        }
        fclose(fp);
    }
    return "What??";
}

int get_mute()
{
    char buffer[128];
    FILE* fp = popen("pactl get-sink-mute @DEFAULT_SINK@", "r");
    if (!fp) return -1;
    fgets(buffer, sizeof(buffer), fp);
    fclose(fp);
    return strstr(buffer, "Mute: yes") != NULL;
}

void volume_up()
{
    const gchar* current_volume = get_volume();

    int current_vol = atoi(current_volume);
    int max_vol = atoi(max_volume);
    int volume_increase = atoi(volume_adjustment);

    int new_volume = current_vol + volume_increase;

    if (new_volume >= max_vol)
        new_volume = max_vol;

    char vol_str[16];
    snprintf(vol_str, sizeof(vol_str), "%d%%", new_volume);
    run_pactl("set-sink-volume", vol_str);
}

void volume_down()
{
    char vol_str[16];
    snprintf(vol_str, sizeof(vol_str), "-%s%%", volume_adjustment);
    run_pactl("set-sink-volume", vol_str);
}

//end------------------------------

//Signal
void handle_update_signal(int signum);

void prevent_double_run()
{
    FILE* f = fopen("/tmp/volume-pulse.pid", "r");
    if (!f) return;
    pid_t pid;
    fscanf(f, "%d", &pid);
    if (kill(pid, 0) == 0)
    {
        printf("volume-pulse is already running!\n");
        fclose(f);
        exit(0);
    }
    fclose(f);
}

void send_update_signal()
{
    FILE* f = fopen("/tmp/volume-pulse.pid", "r");
    if (!f) return;
    pid_t pid;
    fscanf(f, "%d", &pid);
    if (kill(pid, 0) == 0)
        kill(pid, SIGUSR1);
    else
        printf("WARNING:volume-pulse is not running!\n");
    fclose(f);
    exit(0);
}

void* signal_root(void* data)
{
    FILE* f = fopen("/tmp/volume-pulse.pid", "w");
    if (f)
    {
        fprintf(f, "%d\n", getpid());
        fclose(f);
    }

    signal(SIGUSR1, handle_update_signal);

    while (1) pause();
}

//end

//Arguments
void parse_arguments(int argc, char* argv[])
{
    int opt;
    while ((opt = getopt(argc, argv, "hmidlv")) != -1)
    {
        switch (opt)
        {
        case 'h':
            printf("Usage:\n");
            printf("  -h          Show this help message\n");
            printf("  -m          Toggle mute\n");
            printf("  -i          Increase volume\n");
            printf("  -d          Decrease volume\n");
            printf("  -l          Show volume level\n");
            printf("  -v          Output version number and exit\n");
            printf("\t\t config path:  ~/.config/volume-pulse/config.conf\n");
            exit(0);
        case 'm':
            run_pactl("set-sink-mute", "toggle");
            if (get_mute()) printf("Muted : YES");
            else printf("Muted : NO");
            send_update_signal();
        case 'i':
            volume_up();
            send_update_signal();
        case 'd':
            volume_down();
            send_update_signal();
        case 'l':
            printf("%s", get_volume());
            send_update_signal();
        case 'v':
            printf("Volume Pulse %s", version);
            send_update_signal();
        default:
            fprintf(stderr, "Usage: %s [-h] [-m toggle mute] [-u volume up] [-d volume down] [-s show volume level]\n",
                    argv[0]);
            exit(1);
        }
    }
}

//end-----------

//Notification
void show_notification(const char* message)
{
    if (!use_notifications)
        return;

    if (current_notification != NULL)
        notify_notification_close(current_notification, NULL);
    else
        current_notification = notify_notification_new("Volume", message, "audio-volume-medium");

    if (get_mute())
        notify_notification_update(current_notification, "Volume", message, "audio-volume-muted");
    else
    {
        const int vol = atoi(current_volume);
        if (vol == 0)
            notify_notification_update(current_notification, "Volume", message,
                "audio-volume-muted");
        else if (vol <= 30)
            notify_notification_update(current_notification, "Volume", message,
                "audio-volume-low");
        else if (vol <= 70)
            notify_notification_update(current_notification, "Volume", message,
                "audio-volume-medium");
        else
            notify_notification_update(current_notification, "Volume", message,
                "audio-volume-high");
    }
    notify_notification_set_timeout(current_notification, 1000);
    notify_notification_show(current_notification, NULL);
}

//end-----------

//Volume Status
void volume_icon_status()
{
    if (get_mute())
    {
        gtk_status_icon_set_tooltip_text(tray_icon, "Volume: Muted");
        gtk_status_icon_set_from_icon_name(tray_icon, "audio-volume-muted");
    }
    else
    {
        const int vol = atoi(current_volume);
        gtk_status_icon_set_tooltip_text(tray_icon, g_strdup_printf("Volume: %s", current_volume));
        if (vol == 0)
            gtk_status_icon_set_from_icon_name(tray_icon, "audio-volume-muted");
        else if (vol <= 30)
            gtk_status_icon_set_from_icon_name(tray_icon, "audio-volume-low");
        else if (vol <= 70)
            gtk_status_icon_set_from_icon_name(tray_icon, "audio-volume-medium");
        else
            gtk_status_icon_set_from_icon_name(tray_icon, "audio-volume-high");
    }
}

void update_current_volume()
{
    const gchar* volume = get_volume();
    strncpy(current_volume, volume, MAX_VOLUME_LEN - 1);
    current_volume[MAX_VOLUME_LEN - 1] = '\0';
    volume_icon_status();
    show_notification(volume);
}

static gboolean update_scheduled = FALSE;

gboolean update_volume_safe(gpointer data)
{
    update_current_volume();
    update_scheduled = FALSE;
    return G_SOURCE_REMOVE;
}

void handle_update_signal(int signum)
{
    update_scheduled = TRUE;
    g_idle_add(update_volume_safe, NULL);
}

//end------------------------------

// Volume Shortcut Keys
void listen_volume_keys()
{
    XInitThreads();
    Display* dpy = XOpenDisplay(NULL);
    if (!dpy)
    {
        fprintf(stderr, "Cannot open display\n");
        return;
    }

    const Window root = DefaultRootWindow(dpy);

    XGrabKey(dpy, XKeysymToKeycode(dpy, XF86XK_AudioLowerVolume), AnyModifier, root, True, GrabModeAsync,
        GrabModeAsync);
    XGrabKey(dpy, XKeysymToKeycode(dpy, XF86XK_AudioRaiseVolume), AnyModifier, root, True, GrabModeAsync,
        GrabModeAsync);
    XGrabKey(dpy, XKeysymToKeycode(dpy, XF86XK_AudioMute), AnyModifier, root, True, GrabModeAsync,
        GrabModeAsync);

    XSelectInput(dpy, root, KeyPressMask);

    XEvent ev;
    while (1)
    {
        XNextEvent(dpy, &ev);
        if (ev.type == KeyPress)
        {
            XKeyEvent xkey = ev.xkey;
            KeySym keysym = XKeycodeToKeysym(dpy, xkey.keycode, 0);

            if (keysym == XF86XK_AudioRaiseVolume)
            {
                volume_up();
                if (!update_scheduled)
                {
                    update_scheduled = TRUE;
                    g_idle_add(update_volume_safe, NULL);
                }
            }

            else if (keysym == XF86XK_AudioLowerVolume)
            {
                volume_down();
                if (!update_scheduled)
                {
                    update_scheduled = TRUE;
                    g_idle_add(update_volume_safe, NULL);
                }
            }

            else if (keysym == XF86XK_AudioMute)
            {
                run_pactl("set-sink-mute", "toggle");
                g_idle_add(update_volume_safe, NULL);
            }
        }
    }
}

//end------------------------------
//##GTK
void handle_mouse_event(const gchar* type, GdkEvent* event)
{
    if (event->type == GDK_SCROLL)
    {
        GdkEventScroll* sevent = (GdkEventScroll*)event;
        if (sevent->direction == GDK_SCROLL_UP)
        {
            volume_down();
            if (!update_scheduled)
            {
                update_scheduled = TRUE;
                g_idle_add(update_volume_safe, NULL);
            }
        }
        else if (sevent->direction == GDK_SCROLL_DOWN)
        {
            volume_up();
            if (!update_scheduled)
            {
                update_scheduled = TRUE;
                g_idle_add(update_volume_safe, NULL);
            }
        }
    }
    else if (event->type == GDK_BUTTON_PRESS)
    {
        GdkEventButton* bevent = (GdkEventButton*)event;
        if (bevent->button == 1) // Left Click
        {
            run_pactl("set-sink-mute", "toggle");
            g_idle_add(update_volume_safe, NULL);
        }
        else if (bevent->button == 2) // Midden Click
        {
            if (strcmp(middle_click_action, "mixer") == 0)
                run_mixer_app();
            else if (strcmp(middle_click_action, "mute") == 0)
            {
                run_pactl("set-sink-mute", "toggle");
                g_idle_add(update_volume_safe, NULL);
            }
            // free
        }
    }
}

void run_mixer(GtkMenuItem* item, gpointer data)
{
    run_mixer_app();
}

void show_about_panel(GtkMenuItem* item, gpointer data)
{
    GtkWidget* about = gtk_about_dialog_new();
    gtk_about_dialog_set_program_name(GTK_ABOUT_DIALOG(about), "Volume Pulse");
    gtk_about_dialog_set_version(GTK_ABOUT_DIALOG(about), version);
    gtk_about_dialog_set_comments(GTK_ABOUT_DIALOG(about), "      Volume control for your system tray.      ");
    gtk_about_dialog_set_website(GTK_ABOUT_DIALOG(about), "https://vc-365.ir/volume-pulse");
    gtk_about_dialog_set_website_label(GTK_ABOUT_DIALOG(about), "Website");
    gtk_about_dialog_set_copyright(GTK_ABOUT_DIALOG(about), "Proprietary. All rights reserved.");

    GdkPixbuf* logo = gtk_icon_theme_load_icon(gtk_icon_theme_get_default(), "audio-volume-high", 48, 0, NULL);
    if (logo)
        gtk_about_dialog_set_logo(GTK_ABOUT_DIALOG(about), logo);

    gtk_dialog_run(GTK_DIALOG(about));
    gtk_widget_destroy(about);
}

void run_quit(GtkMenuItem* item, gpointer data)
{
    gtk_main_quit();
}

static gboolean on_scroll_event(GtkStatusIcon* status_icon, GdkEventScroll* event, gpointer user_data)
{
    handle_mouse_event("scroll", (GdkEvent*)event);
    return TRUE;
}

static gboolean on_button_press(GtkStatusIcon* status_icon, GdkEventButton* event, gpointer user_data)
{
    handle_mouse_event("button-press", (GdkEvent*)event);
    return FALSE;
}

static void on_popup_menu(GtkStatusIcon* status_icon, const guint button, const guint activate_time, gpointer user_data)
{
    GtkWidget* menu = gtk_menu_new();

    GtkWidget* mixerX = gtk_menu_item_new_with_label("Open Mixer");
    g_signal_connect(mixerX, "activate", G_CALLBACK(run_mixer), NULL);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), mixerX);

    GtkWidget* about = gtk_menu_item_new_with_label("About");
    g_signal_connect(about, "activate", G_CALLBACK(show_about_panel), NULL);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), about);

    GtkWidget* quit = gtk_menu_item_new_with_label("Quit");
    g_signal_connect(quit, "activate", G_CALLBACK(run_quit), NULL);
    gtk_menu_shell_append(GTK_MENU_SHELL(menu), quit);

    gtk_widget_show_all(menu);
    gtk_menu_popup(GTK_MENU(menu), NULL, NULL, NULL, NULL, button, activate_time);
}

//##end-------------------

int main(int argc, char* argv[])
{
    read_config();
    parse_arguments(argc, argv);
    prevent_double_run();
    if (use_notifications)
        notify_init("Volume Notifier");
    FcInit();
    gtk_init(&argc, &argv);

    tray_icon = gtk_status_icon_new_from_icon_name("audio-volume-high");
    update_current_volume();

    g_signal_connect(G_OBJECT(tray_icon), "scroll-event", G_CALLBACK(on_scroll_event), NULL);
    g_signal_connect(G_OBJECT(tray_icon), "button-press-event", G_CALLBACK(on_button_press), NULL);
    g_signal_connect(G_OBJECT(tray_icon), "popup-menu", G_CALLBACK(on_popup_menu), NULL);
    if (use_shortcuts) { g_thread_new("volume_keys_thread", (GThreadFunc)listen_volume_keys, NULL); }
    if (use_arguments) { g_thread_new("volume-session", signal_root, NULL); }

    gtk_main();
    if (use_notifications) { notify_uninit(); }
    return 0;
}
