ARG VARIANT=latest
ARG BASEIMAGE=ubuntu
FROM ${BASEIMAGE}:${VARIANT} as runner
ARG FASTBUILDVERSION="v1.08"
ADD https://fastbuild.org/downloads/v1.08/FASTBuild-Linux-x64-${FASTBUILDVERSION}.zip /tmp/fastbuild
RUN apt-get update -y && apt-get install -y unzip 
RUN unzip /tmp/fastbuild -d /usr/local/bin/ && rm /tmp/fastbuild && chmod +x /usr/local/bin/fbuild* && ls -ltr /usr/local/bin

FROM ${BASEIMAGE}:${VARIANT} as runtime
COPY --from=runner /usr/local/bin/fbuild* /usr/local/bin/
VOLUME [ "/data" ]
ENV FASTBUILD_CACHE_PATH =/data/cache
ENV FASTBUILD_CACHE_MODE=rw
ENV FASTBUILD_BROKERAGE_PATH=/data/broker
EXPOSE 31264

ENTRYPOINT [ "fbuildworker" ]
