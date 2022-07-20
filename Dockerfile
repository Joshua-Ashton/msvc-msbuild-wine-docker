FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London
ENV WINEDEBUG=-all

RUN dpkg --add-architecture i386

RUN apt-get update && \
    apt-get install -y wget

RUN wget -nc -O /usr/share/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN wget -nc -P /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/focal/winehq-focal.sources

RUN apt-get update && \
    apt-get install -y winehq-staging python msitools python-simplejson \
                       python-six ca-certificates winbind winetricks weston xinit libgl1-mesa-dev && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

RUN wine64 wineboot --init && \
    while pgrep wineserver > /dev/null; do sleep 1; done

RUN winetricks -f -q dotnet472

WORKDIR /msvc-temp
RUN wget https://aka.ms/vs/17/release/vs_buildtools.exe
RUN wget https://aka.ms/vs/17/release/installer
RUN mv installer installer.zip
RUN unzip installer.zip -d installer_data
RUN mkdir -p "$HOME/.wine/drive_c/Program Files (x86)/Microsoft Visual Studio/Installer"
RUN cp -r installer_data/Contents/* "$HOME/.wine/drive_c/Program Files (x86)/Microsoft Visual Studio/Installer"

RUN mkdir -p /tmp/.X11-unix

RUN XDG_RUNTIME_DIR="$HOME" weston --use-pixman --backend=headless-backend.so --xwayland & \
    DISPLAY=:0 wine vs_buildtools --wait --quiet --includeRecommended --includeOptional --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Workload.MSBuildTools || true