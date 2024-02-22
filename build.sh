#!/bin/bash
# shellcheck disable=SC2086
# shellcheck disable=SC1091
# shellcheck disable=SC2154
# shellcheck disable=SC2199
# shellcheck disable=SC2181
# shellcheck disable=SC2155
# shellcheck disable=SC2059

ROOT_PATH=$(pwd)
BUILD_PATH=${ROOT_PATH}/build
INSTALL_PATH=${ROOT_PATH}/install

log_err() {
	local logTime="$(date -d today +'%Y-%m-%d %H:%M:%S')"
	printf "\033[0;31m[ERROR][${logTime}][${FUNCNAME[1]}] $*\r\n\033[0m"
}

log_warn() {
	local logTime="$(date -d today +'%Y-%m-%d %H:%M:%S')"
	printf "\033[0;33m[WARN][${logTime}][${FUNCNAME[1]}] $*\r\n\033[0m"
}

log_info() {
	local logTime="$(date -d today +'%Y-%m-%d %H:%M:%S')"
	printf "\033[0;32m[INFO][${logTime}][${FUNCNAME[1]}] $*\r\n\033[0m"
}

check_config() {
	local BUILD_CFG=$1
	if [[ ${BUILD_CFG} != "Debug" && ${BUILD_CFG} != "Release" ]]; then
		log_err "输入参数错误"
		log_err "请输入Debug或者Release"
		return 1
	fi

	return 0
}

conan_config() {
	local BUILD_CFG=$1
	check_config ${BUILD_CFG} || exit 1

	log_info "配置conan"
	conan install conanfile.txt --build=missing -s build_type=${BUILD_CFG} || exit 1
}

cmake_preset()
{
	local BUILD_CFG=$1
	check_config ${BUILD_CFG} || exit 1

	if [ ${BUILD_CFG} == "Debug" ]; then
		cmake --preset conan-debug || exit 1
	elif [ ${BUILD_CFG} == "Release" ]; then
		cmake --preset conan-release || exit 1
	fi
}

cmake_config()
{
	local BUILD_CFG=$1
	local BUILD_COV=$2

	check_config ${BUILD_CFG} || exit 1

	log_info "cmake配置 build:${BUILD_CFG} coverage:${BUILD_COV}"

	cmake -DCMAKE_POLICY_DEFAULT_CMP0091=NEW \
		-DCMAKE_BUILD_TYPE="${BUILD_CFG}" \
		-DBUILD_COVERAGE=ON \
		-DCMAKE_TOOLCHAIN_FILE="${ROOT_PATH}"/build/"${BUILD_CFG}"/generators/conan_toolchain.cmake \
		-S "${ROOT_PATH}" \
		-B "${ROOT_PATH}"/build \
		-G Ninja || exit 1
}

cmake_build()
{
	local BUILD_CFG=$1
	check_config ${BUILD_CFG} || exit 1

	cmake --build ${BUILD_PATH} --config "${BUILD_CFG}" -j"$(nproc)" || exit 1
}

cmake_ctest()
{
	local BUILD_CFG=$1
	check_config ${BUILD_CFG} || exit 1

	ctest -C "${BUILD_CFG}" --test-dir ${BUILD_PATH}/test || exit 1
}

cmake_cov()
{
	local BUILD_COV=$1

	cmake --build ${BUILD_PATH} --config "${BUILD_CFG}" --target TestXml  || exit 1
	cmake --build ${BUILD_PATH} --config "${BUILD_CFG}" --target TestHtml || exit 1
}

setup_pkg()
{
	pushd dpdk >> /dev/null || exit 1
	if [ ! -d build ]; then
		mkdir build
		meson build --prefix=${INSTALL_PATH}
		ninja -C build
		ninja -C build install
	fi
	popd >> /dev/null || exit 1
}

build() {
	local BUILD_CFG=$1
	local BUILD_COV=$2

	check_config ${BUILD_CFG} || exit 1

	log_info "删除临时文件夹"
	[ -d "${BUILD_PATH}" ] && rm -rf "${BUILD_PATH}"
	mkdir -p ${BUILD_PATH}

	log_info "开始构建"

	check_config 	${BUILD_CFG} || exit 1
	conan_config 	${BUILD_CFG} || exit 1
	cmake_preset 	${BUILD_CFG} || exit 1
	cmake_config 	${BUILD_CFG} ${BUILD_COV} || exit 1
	cmake_build  	${BUILD_CFG} || exit 1
	cmake_ctest  	${BUILD_CFG} || exit 1
	[ ${BUILD_COV} = true ] && cmake_cov ${BUILD_COV}  || exit 1

	log_info "构建结束"
}

usage() {
	log_err "输入参数错误"
	log_err "请输入Debug或者Release"
}

#############################################
#               构建脚本起点                 #
#############################################
BUILD_CFG="Debug"
BUILD_ALL=false
BUILD_COV=false
SETUP_PKG=false

# 判断输入参数个数
if [ $# == 0 ]; then
	usage
	exit 1
fi

# 解析输入参数
ARGS=$(getopt -o bc:ls -l build,config:,coverage,setup -- "$@")
if [ $? != 0 ]; then
	log_err "args parse error" >&2
	exit 1
fi

# 展开输入
eval set -- "${ARGS}"
while true; do
	case "${1}" in
	-c | --config)
		BUILD_CFG=${2}
		shift 2
		;;

	-b | --build)
		BUILD_ALL=true
		shift 1
		;;

	-l | --coverage)
		BUILD_COV=true
		shift 1
		;;

	-s | --setup)
		SETUP_PKG=true
		shift 1
		;;

	--)
		shift
		break
		;;

	*)
		usage
		exit
		;;
	esac
done

log_info "检查输入参数"
check_config ${BUILD_CFG} || exit 1
log_info "参数输入正确"

if [ ${SETUP_PKG} = true ];
then
	log_info "编译DPDK开始"
	setup_pkg || exit 1
	log_info "编译DPDK完成"
fi

if [ ${BUILD_ALL} = true ];
then
	build ${BUILD_CFG} ${BUILD_COV}
fi
