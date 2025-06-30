.PHONY: linux chrome windows ios build test

app-icons:
	dart run flutter_launcher_icons

config:
ifeq ($(OS),Windows_NT)
	powershell new-item .env.local
else
	touch .env.local
	cd scripts; sh ./generate_local_config.sh
endif

models:
	dart run build_runner build --delete-conflicting-outputs

# To pass a sub version string to make, use 'make SUB_VERSION=xyz build_windows'.
# SUB_VERSION string for debian must not have ':' to be mistaken as an epoch.
# The debian version format is: [epoch:]upstream_version[-debian_revision]:
# 	https://www.debian.org/doc/debian-policy/ch-controlfields.html#version
git_branch=$(shell git branch --show-current)
ifeq ($(OS),Windows_NT)
    date=$(shell powershell -NoProfile Get-Date -Format "yyMMdd-HH:mm")
    user=$(shell powershell -NoProfile $$env:UserName)
    branch=$(shell powershell \"${git_branch}\".Substring(0,[math]::Min(10,\"${git_branch}\".length)))
else
    date=$(shell date +%y%m%d.%H.%M)
    user=${USER}
    branch=$(shell echo ${git_branch} | cut -c1-10)
endif
git_hash=$(shell git rev-parse --short HEAD)
git_version=${date}-${branch}-${git_hash}
sub_version=${git_version}
ifneq ($(shell git status --short),)
    sub_version ="${git_version}-d"
endif
SUB_VERSION?=${sub_version}
subver:
	@echo "platform is ${OS} date ${date} user ${user} ${branch}"
	@echo "sub version is ${SUB_VERSION}"

# build package
build=flutter build -v $1 ${DART_DEFINES} $2

# android build
apk: copy_ipn_aar
	$(call build,apk,--split-per-abi --target-platform android-arm64)
appbundle: copy_ipn_aar
	$(call build,appbundle)
ipn_aar:
	cd tailscale-android && make libtailscale android/libs/ipn_app.aar
copy_ipn_aar:
	mkdir -p android/app/libs/
	cp tailscale-android/android/libs/ipn_app.aar android/app/libs/.
	cp tailscale-android/android/libs/libtailscale.aar android/app/libs/ipn.aar
aab:
	flutter build appbundle

# apple build:
# please use the Xcode project

# windows build:
SIGN_CMD=signtool.exe
EXE_PATH="windows\installer\bin\CylonixInstaller.msi"

# To be executed in the wsl terminal
windows_cylonixd:
	cd ./tailscale && BUILD_NUMBER=${BUILD_NUMBER} GOOS=windows GOARCH=amd64 ./build_dist.sh tailscale.com/cmd/tailscaled 
	cd ./tailscale && BUILD_NUMBER=${BUILD_NUMBER} GOOS=windows GOARCH=amd64 ./build_dist.sh tailscale.com/cmd/tailscale
	mv ./tailscale/tailscaled.exe windows/installer/cylonixd.exe
	mv ./tailscale/tailscale.exe windows/installer/cylonixc.exe
# To be executed in the cmd or powershell terminal
build_windows:
	flutter build windows --release
pack_windows:
	cd .\windows\installer && powershell -ExecutionPolicy Bypass -File .\build.ps1
sign_windows:
	${SIGN_CMD} sign /tr http://timestamp.sectigo.com /td sha256 /fd sha256 /a ${EXE_PATH}
install_windows:
	$(shell powershell ${EXE_PATH})

# docker builds
GO_COMMIT_ID=$(shell cat tailscale/go.toolchain.rev)
GO_PACKAGE=tailscale-go-${GO_COMMIT_ID}.tar.gz
DOCKER_IMAGE=cylonix_build_docker_image
DOCKER_CONTAINER=cylonix_build_docker_container
FLUTTER_STORAGE_SITE?=storage.googleapis.com
FLUTTER_PUB_HOSTED_URL?=https://pub.dartlang.org

docker_builder:
	echo FLUTTER_STORAGE_SITE=${FLUTTER_STORAGE_SITE}
	docker rm -f ${DOCKER_CONTAINER}
	docker build \
		-f docker/Dockerfile \
		--network=host \
		--build-arg GO_COMMIT_ID=${GO_COMMIT_ID} \
		--build-arg FLUTTER_STORAGE_SITE=${FLUTTER_STORAGE_SITE} \
		--build-arg FLUTTER_PUB_HOSTED_URL=${FLUTTER_PUB_HOSTED_URL} \
		--build-arg GOPROXY=${GOPROXY} \
		-t ${DOCKER_IMAGE} \
		.

docker_deb:
	rm -rf build
	docker run -it --rm \
		-v ${PWD}:/app \
		-v /etc/timezone:/etc/timezone:ro \
		-v /etc/localtime:/etc/localtime:ro \
		--name ${DOCKER_CONTAINER} \
		--network=host \
		${DOCKER_IMAGE} bash -c "export PUB_HOSTED_URL=${FLUTTER_PUB_HOSTED_URL}; flutter pub -v get; export GOPROXY=${GOPROXY}; make deb"

.PHONY: deb
debhelper golang-go:
	@if dpkg-query -Wf'$${db:Status-abbrev}' $@ 2>/dev/null |  \
		grep -q '^i'; then                                     \
			echo $@ has been installed;                        \
		else                                                   \
			sudo apt-get update && sudo apt-get install -y $@; \
		fi
deb: debhelper golang-go
	rm -rf linux/packaging/debian/cylonix
	cd linux/packaging; dpkg-buildpackage -rfakeroot -uc -b
	mv linux/cylonix* build/linux/x64/release/.
	@ls -l build/linux/x64/release/cylonix*
