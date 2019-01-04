# For travis
FROM buildpack-deps:xenial
SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8
RUN mkdir -p /root/emsdk/
COPY . /root/emsdk/

RUN cd /root/ \
 && echo "int main() {}" > hello_world.cpp \
 && apt-get update \
 && apt-get install -y python cmake build-essential openjdk-9-jre-headless \
 && /root/emsdk/emsdk update-tags \
 && echo "test latest" \
 && /root/emsdk/emsdk install latest \
 && /root/emsdk/emsdk activate latest \
 && source /root/emsdk/emsdk_env.sh --build=Release \
 && emcc hello_world.cpp -o a.out.js \
 && echo "test upstream (waterfall)" \
 && /root/emsdk/emsdk install latest-upstream \
 && /root/emsdk/emsdk activate latest-upstream \
 && source /root/emsdk/emsdk_env.sh --build=Release \
 && emcc hello_world.cpp -s WASM_OBJECT_FILES=1 -o b.out.js \
 && echo "test fastcomp (waterfall)" \
 && /root/emsdk/emsdk install latest-fastcomp \
 && /root/emsdk/emsdk activate latest-fastcomp \
 && source /root/emsdk/emsdk_env.sh --build=Release \
 && emcc hello_world.cpp -o c.out.js \
 && emcc hello_world.cpp -s WASM=0 -o d.out.js \
 && echo "text executions" \
 && /root/emsdk/node/8.9.1_64bit/bin/node a.out.js &> o \
 && ls -al o \
 && cat o \
 && echo \
 && /root/emsdk/node/8.9.1_64bit/bin/node b.out.js &> o \
 && ls -al o \
 && cat o \
 && echo \
 && /root/emsdk/node/8.9.1_64bit/bin/node c.out.js &> o \
 && ls -al o \
 && cat o \
 && echo \
 && /root/emsdk/node/8.9.1_64bit/bin/node d.out.js &> o \
 && ls -al o \
 && cat o \
 && echo

