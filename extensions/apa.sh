# Install armbian-common etc. from APA

function extension_prepare_config__apa() {
	display_alert "Target image will have Armbian Package Archive (APA) enabled by default" "${EXTENSION}" "info"
	export APA_IS_ACTIVE="true"
}

function custom_apt_repo__add_apa() {
	run_host_command_logged echo "deb [signed-by=${APT_SIGNING_KEY_FILE}] http://github.armbian.com/apa current main" "|" tee "${SDCARD}"/etc/apt/sources.list.d/armbian-apa.list

#	# remove later
#	run_host_command_logged cp "${SRC}/lib/tools/apt-install-first-level-deps.py" "${SDCARD}"/root/
#	chroot_sdcard_apt_get_update
#	chroot_sdcard apt policy lightdm armbian-desktop-xfce || true
#	chroot_sdcard find /etc/apt/sources.list.d/
#	echo "midway through"
##	chroot_sdcard find /etc/apt/sources.list.d/ -exec cat {} \;
#	chroot_sdcard ls -l /etc/apt/sources.list.d/
#	chroot_sdcard whoami
#	chroot_sdcard_apt_get install python3-apt
##	chroot_sdcard cat /etc/apt/sources.list.d/*
#	chroot_sdcard python3 /root/apt-install-first-level-deps.py recommends lightdm
#	# until here
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
			chroot_sdcard apt update # remove this later XXX
#			chroot_sdcard_apt_get install --no-install-recommends "python3-apt armbian-desktop-${APA_DESKTOP_ENVIRONMENT,,}"
#			chroot_sdcard apt policy base-files
#			chroot_sdcard dpkg -l "*${APA_DESKTOP_ENVIRONMENT,,}*"
			chroot_sdcard apt policy armbian-common lightdm armbian-desktop-xfce || true
#			chroot_sdcard find /etc/apt/sources.list.d/
#			chroot_sdcard ls -l /etc/apt/sources.list.d/
#			chroot_sdcard cat /etc/apt/sources.list.d/debian.sources

			# XXX: would it be better to call the python script at a later stage in core? apt doesn't seem to be quite correcly set up yet
			chroot_sdcard mkdir -pv /var/cache/apt/archives/ /var/cache/apt/archives/partial/
#			chroot_sdcard touch /var/cache/apt/archives/lock
#			chroot_sdcard python3 /root/apt-install-first-level-deps.py recommends lightdm
			chroot_sdcard python3 /root/apt-install-first-level-deps.py recommends armbian-desktop-${APA_DESKTOP_ENVIRONMENT,,}
			# purge python3-apt and others
			ls -l "/root/apt-install-first-level-deps.py" || true
			ls -l /root/apt-install-first-level-deps.py || true
			file "/root/apt-install-first-level-deps.py" || true
			# XXX: remove the inactive file for apt sources
			;;
	esac
}
