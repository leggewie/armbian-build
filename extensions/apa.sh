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
	chroot_sdcard rm /etc/apt/sources.list.d/armbian-apa.list.inactive || true

	# install desktop environment if requested
	case ${APA_DESKTOP_ENVIRONMENT^^} in
		XFCE|KDE|GNOME)
			display_alert "installing ${APA_DESKTOP_ENVIRONMENT^^} desktop environment" "${EXTENSION}: ${APA_DESKTOP_ENVIRONMENT^^}" "info"
			chroot_sdcard apt update # remove this later XXX, as of now, it still seems to be necessary, cache.update() in the python script is not sufficient
			#chroot_sdcard apt policy armbian-common lightdm armbian-desktop-xfce || true
			run_host_command_logged cp "${SRC}/lib/tools/apt-install-first-level-deps.py" "${SDCARD}"/root/

			# XXX: would it be better to call the python script at a later stage in core? apt doesn't seem to be quite correcly set up yet
			# XXX: there is a probably related problem with this stuff not being sandboxed -> [🐳|🚸] SDCARD /var/lib/apt/lists is not empty [ /var/lib/apt/lists :: 31 files ]

			chroot_sdcard mkdir -pv /var/cache/apt/archives/ /var/cache/apt/archives/partial/
			chroot_sdcard python3 /root/apt-install-first-level-deps.py recommends armbian-desktop-${APA_DESKTOP_ENVIRONMENT,,}
			rm -v "${SDCARD}"/root/apt-install-first-level-deps.py && sleep 30
			;;
	esac
}
