# Install armbian-common etc. from APA

function extension_prepare_config__apa() {
	display_alert "Target image will have Armbian Package Archive (APA) enabled by default" "${EXTENSION}" "info"
	export APA_IS_ACTIVE="true"
}

function custom_apt_repo__add_apa() {
	run_host_command_logged echo "deb [signed-by=${APT_SIGNING_KEY_FILE}] http://github.armbian.com/apa current main" "|" tee "${SDCARD}"/etc/apt/sources.list.d/armbian-apa.list
}

function post_armbian_repo_customize_image__install_from_apa() {
	# do not install armbian recommends for minimal images
	[[ "${BUILD_MINIMAL,,}" =~ ^(true|yes)$ ]] && INSTALL_RECOMMENDS="no-install-recommends" || INSTALL_RECOMMENDS="install-recommends"
	chroot_sdcard_apt_get --$INSTALL_RECOMMENDS install "armbian-common armbian-bsp"

	# install desktop environment if requested
	case ${APA_DESKTOP_ENVIRONMENT^^} in
		XFCE|KDE|GNOME)
			display_alert "installing ${APA_DESKTOP_ENVIRONMENT^^} desktop environment" "${EXTENSION}: ${APA_DESKTOP_ENVIRONMENT^^}" "info"
			#chroot_sdcard_apt_get install --install-recommends=yes "armbian-desktop-${APA_DESKTOP_ENVIRONMENT,,}"
			run_host_command_logged cp "${SRC}/lib/tools/apt-install-first-level-deps.py" "${SDCARD}"/root/
		        #python3 "${SRC}/lib/tools/apt-install-first-level-deps.py" "--args" "${ARTIFACTS_VAR_DICT[@]}" # to stdout
		        #chroot_sdcard python3 "${SRC}/lib/tools/apt-install-first-level-deps.py" "recommends" "armbian-desktop-${APA_DESKTOP_ENVIRONMENT,,}"
			chroot_sdcard_apt_get_update
#			chroot_sdcard_apt_get install --no-install-recommends "python3-apt armbian-desktop-${APA_DESKTOP_ENVIRONMENT,,}"
#			chroot_sdcard apt policy base-files
#			chroot_sdcard dpkg -l "*${APA_DESKTOP_ENVIRONMENT,,}*"
			chroot_sdcard apt policy armbian-common
		        chroot_sdcard python3 "/root/apt-install-first-level-deps.py" "recommends" "lightdm"
		        chroot_sdcard python3 "/root/apt-install-first-level-deps.py" "recommends" "armbian-desktop-${APA_DESKTOP_ENVIRONMENT,,}"
			# purge python3-apt and others
			ls -l "/root/apt-install-first-level-deps.py" || true
			ls -l /root/apt-install-first-level-deps.py || true
			file "/root/apt-install-first-level-deps.py" || true
			;;
	esac
}
