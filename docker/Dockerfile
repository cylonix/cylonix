FROM ubuntu:20.04 AS cylonix_docker_build_base
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
        apt install -y wget file git curl unzip make xz-utils zip libglu1-mesa \
        vim cmake ninja-build clang pkg-config build-essential libgtk-3-dev \
        liblzma-dev

# Now build everything under user "cylonix".
RUN useradd -ms /bin/bash cylonix
USER cylonix
WORKDIR /home/cylonix

# Download and install go.
RUN wget https://golang.org/dl/go1.23.4.linux-amd64.tar.gz
RUN tar zxvf go1.23.4.linux-amd64.tar.gz && rm -f go1.23.4.linux-amd64.tar.gz
ENV PATH="/home/cylonix/go/bin:${PATH}"

# Build and package customized go with the specific tag.
ARG GO_COMMIT_ID
RUN mkdir ~/.cache/
RUN cd ~/.cache/ && git clone -v https://github.com/tailscale/go.git
RUN cd ~/.cache/go && git checkout ${GO_COMMIT_ID}
RUN cd ~/.cache/go/src && ./all.bash
RUN cd ~/.cache/go && rm -rf pkg/linux_amd64 pkg/obj
RUN cd ~/.cache/ && tar zcvf ~/.cache/tailscale-go-${GO_COMMIT_ID}.tar.gz go
RUN echo "Done building go with tag ${GO_COMMIT_ID}"

# Make the customized go as the go command path.
RUN mv ~/.cache/go ~/.cache/tailscale-go
RUN echo "${GO_COMMIT_ID}" > ~/.cache/tailscale-go.extracted
ENV PATH="/home/cylonix/.cache/tailscale-go/bin:${PATH}"
ENV GOROOT=

# Choose flutter archive site.
ARG FLUTTER_STORAGE_SITE
RUN wget https://${FLUTTER_STORAGE_SITE}/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
RUN tar -xvf ./flutter_linux_3.24.5-stable.tar.xz
ENV PATH="${PATH}:/home/cylonix/flutter/bin"

WORKDIR /app-preload
COPY ./tailscale/go.mod ./tailscale/go.sum ./tailscale/

# Preload go dependencies
ARG GOPROXY
RUN export GOPROXY=${GOPROXY}; cd ./tailscale && go mod download -x

# Uncomment the following once all local plugins are removed.
#COPY pubspec.yaml pubspec.lock ./
# Preload flutter dependencies
#ARG FLUTTER_PUB_HOSTED_URL
#RUN export PUB_HOSTED_URL=${FLUTTER_PUB_HOSTED_URL}; flutter pub get

# Reset back to full app source to be passed in with docker run.
WORKDIR /app

RUN ls ~/.cache/tailscale-go/bin
RUN echo ${PATH}
RUN which go
CMD ["go", "version"]
