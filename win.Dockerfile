# escape=`
ARG VARIANT=runtime-windows
ARG BASEIMAGE=ghcr.io/epicgames/unreal-engine
FROM ${BASEIMAGE}:${VARIANT}
ARG FASTBUILDVERSION="v1.08"
# https://www.fastbuild.org/downloads/v1.08/FASTBuild-Windows-x64-v1.08.zip

ADD https://www.fastbuild.org/downloads/${FASTBUILDVERSION}/FASTBuild-Windows-x64-${FASTBUILDVERSION}.zip fb.zip
RUN md C:\fastbuild &&  tar -xf fb.zip -C C:\fastbuild && del fb.zip

VOLUME c:\data
ENV FASTBUILD_CACHE_PATH =C:\data\cache
ENV FASTBUILD_CACHE_MODE=rw
ENV FASTBUILD_BROKERAGE_PATH=C:\data\broker

ENTRYPOINT "C:\fastbuild\FBuildWorker.exe -console -cpus=100% -mode=dedicated -nosubprocess"