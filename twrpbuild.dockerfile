FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y \
    repo bc build-essential zip curl libstdc++6 git wget gcc clang libssl-dev rsync flex curl python2 bison aria2 yt-dlp git ccache automake lzop bison gperf zlib1g-dev g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool make optipng maven libncurses5 bc bison ccache curl flex g++-multilib gcc-multilib git git-lfs gnupg gperf imagemagick lib32readline-dev lib32z1-dev libelf-dev liblz4-tool libsdl1.2-dev libssl-dev libxml2 libxml2-utils lzop pngcrush rsync schedtool squashfs-tools xsltproc zip zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN ln -s /usr/bin/python2 /usr/local/bin/python

WORKDIR /root