# escape=`
ARG VARIANT=runtime-windows
ARG BASEIMAGE=ghcr.io/epicgames/unreal-engine
FROM ${BASEIMAGE}:${VARIANT}
ARG FASTBUILDVERSION="v1.08"

ENV FASTBUILD_HOME=C:\fastbuild
ENV FASTBUILD_VERSION=${FASTBUILDVERSION}

COPY scripts C:\fastbuild
WORKDIR C:\fastbuild
# RUN powershell -file installchoco.ps1
RUN powershell -file installtools.ps1

VOLUME C:\data
ENV FASTBUILD_CACHE_PATH=C:\data\cache
ENV FASTBUILD_CACHE_MODE=rw
ENV FASTBUILD_BROKERAGE_PATH=C:\data\broker
EXPOSE 31264

ENTRYPOINT "cmd"