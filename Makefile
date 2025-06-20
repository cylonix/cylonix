.PHONY: linux chrome windows ios build test

app-icons:
	dart run flutter_launcher_icons

config:
	touch .env.local
	cd scripts; sh .//generate_local_config.sh

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

DART_DEFINES=\
	--dart-define=BUILD_SUB_VERSION=${SUB_VERSION}

linux chrome windows macos:
	flutter run -v -d $@ ${DART_DEFINES}

ios:
	flutter run ${DART_DEFINES}

ios-release:
	flutter run --release ${DART_DEFINES}

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

# linux build only supports ubuntu debian packaging for now
debian:
	rm -rf build
	$(call build,linux,)
	make -C tailscale deb
	cd tools/packaging/linux && SUB_VERSION=${SUB_VERSION} bash ./package.sh

# apple build:
# please use the Xcode project

# windows build:
NSIS_CMD="C:\Program Files (x86)\NSIS\makensis.exe"
SIGN_CMD=signtool.exe
PFX_PATH="tools\packaging\windows\cylonix_package_TemporaryKey.pfx"
EXE_PATH="tools\packaging\windows\cylonix_install.exe"
build_windows:
	$(call build,windows)
copy_cylonixd_exe=copy ".\tailscale\build\windows\$1\release\tailscaled.exe" ".\tools\packaging\windows\$2\cylonixd.exe"
copy_cylonixc_exe=copy ".\tailscale\build\windows\$1\release\tailscale.exe" ".\tools\packaging\windows\$2\cylonixc.exe"
pack_nsis=cd tools\packaging\windows && ${NSIS_CMD} \
	-DPRODUCT_SUB_VERSION=${SUB_VERSION} \
	-DPRODUCT_PUBLISHER_EN=${PUBLISHER_EN} \
	-DPRODUCT_WEB_SITE=${PUBLISHER_WEBSITE} \
	-DWIN32=$2 $1
pack_windows:
	$(call copy_cylonixd_exe,amd64,cylonixd)
	$(call copy_cylonixc_exe,amd64,cylonixd)
	$(call pack_nsis,cylonix_ch.nsi)
sign_windows:
	${SIGN_CMD} sign /tr http://timestamp.sectigo.com /td sha256 /fd sha256 /a ${EXE_PATH}
install_windows:
	$(shell powershell ${EXE_PATH})

copy_windows_cylonixd:
	$(call copy_cylonixd_exe,amd64,cylonixd)
	$(call copy_cylonixc_exe,amd64,cylonixd)
pack_windows_cli: copy_windows_cylonixd
	$(call pack_nsis,cylonix_cli_ch.nsi)
pack_win32_cli:
	$(call copy_cylonixd_exe,386,cylonixd)
	$(call copy_cylonixc_exe,386,cylonixd)
	$(call pack_nsis,cylonix_cli_ch.nsi,win32)

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

docker_clean:
	rm -rf build

docker_cylonixd_deb:
	docker run -it --rm \
		-v ${PWD}:/app \
		-v /etc/timezone:/etc/timezone:ro \
		-v /etc/localtime:/etc/localtime:ro \
		--name ${DOCKER_CONTAINER} \
		--network=host \
		${DOCKER_IMAGE} bash -c "export GOPROXY=${GOPROXY}; make -C tailscale deb_amd64"

docker_deb:
	rm -rf build
	docker run -it --rm \
		-v ${PWD}:/app \
		-v /etc/timezone:/etc/timezone:ro \
		-v /etc/localtime:/etc/localtime:ro \
		--name ${DOCKER_CONTAINER} \
		--network=host \
		${DOCKER_IMAGE} bash -c "export PUB_HOSTED_URL=${FLUTTER_PUB_HOSTED_URL}; flutter pub -v get; export GOPROXY=${GOPROXY}; make deb"

docker_go:
	docker run -it --rm \
		-v /tmp:/host-tmp \
		--name ${DOCKER_CONTAINER} \
		--network=host \
		${DOCKER_IMAGE} cp /home/cylonix/.cache/${GO_PACKAGE} /host-tmp/.

docker_go_extracted:
	docker run -it --rm \
		-v /tmp:/host-tmp \
		--name ${DOCKER_CONTAINER} \
		--network=host \
		${DOCKER_IMAGE} cp /home/cylonix/.cache/tailscale-go.extracted /host-tmp/.