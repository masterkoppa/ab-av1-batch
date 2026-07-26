FROM archlinux:latest

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm base-devel git ffmpeg rust && \
    # Build ab-av1 from source (AUR not available directly, use cargo)
    cargo install ab-av1 && \
    mv /root/.cargo/bin/ab-av1 /usr/local/bin/ && \
    # Cleanup build deps
    pacman -Rns --noconfirm rust base-devel git && \
    rm -rf /root/.cargo /root/.rustup && \
    pacman -Scc --noconfirm && \
    yes | pacman -Scc

COPY encode.sh /usr/local/bin/encode.sh

ENV TARGET_CODEC=AV1
ENV MIN_VMAF=95

VOLUME ["/encode-targets", "/output"]

ENTRYPOINT ["encode.sh"]
