# Troubleshoot with this extension

function extension_prepare_config__apa() {
	display_alert "This extension will help in troubleshooting" "${EXTENSION}" "info"
}

function post_armbian_repo_customize_image__troubleshoot() {
	chroot_sdcard find /var/cache/apt/
}
