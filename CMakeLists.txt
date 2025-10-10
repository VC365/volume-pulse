cmake_minimum_required(VERSION 3.16)
project(volume-pulse C)

set(CMAKE_C_STANDARD 11)

find_package(PkgConfig REQUIRED)

pkg_check_modules(GTK2 REQUIRED gtk+-2.0)
pkg_check_modules(X11 REQUIRED x11)
pkg_check_modules(LIBNOTIFY REQUIRED libnotify)

add_executable(volume-pulse src/main.c)

# Include paths
target_include_directories(volume-pulse PRIVATE
        ${GTK2_INCLUDE_DIRS}
        ${X11_INCLUDE_DIRS}
        ${LIBNOTIFY_INCLUDE_DIRS}
)

# Linked libraries
target_link_libraries(volume-pulse
        ${GTK2_LIBRARIES}
        ${X11_LIBRARIES}
        ${LIBNOTIFY_LIBRARIES}
)

# Compiler flags (from pkg-config)
target_compile_options(volume-pulse PRIVATE
        ${GTK2_CFLAGS_OTHER}
        ${X11_CFLAGS_OTHER}
        ${LIBNOTIFY_CFLAGS_OTHER}
)
