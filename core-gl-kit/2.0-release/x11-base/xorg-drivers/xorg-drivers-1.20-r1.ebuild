# Distributed under the terms of the GNU General Public License v2

EAPI=7

DESCRIPTION="Meta package containing deps on all xorg drivers"
HOMEPAGE="https://www.gentoo.org/"
SRC_URI=""

LICENSE="metapackage"
SLOT="0"
KEYWORDS="*"

IUSE_INPUT_DEVICES="
	input_devices_elographics
	input_devices_evdev
	input_devices_joystick
	input_devices_libinput
	input_devices_mouse
	input_devices_tslib
	input_devices_vmmouse
	input_devices_void
	input_devices_synaptics
	input_devices_wacom
"
IUSE_VIDEO_CARDS="
	video_cards_amdgpu
	video_cards_ast
	video_cards_dummy
	video_cards_fbdev
	video_cards_freedreno
	video_cards_geode
	video_cards_glint
	video_cards_i915
	video_cards_i965
	video_cards_intel
	video_cards_mga
	video_cards_nouveau
	video_cards_nv
	video_cards_omap
	video_cards_qxl
	video_cards_r128
	video_cards_radeon
	video_cards_radeonsi
	video_cards_gallium-iris
	video_cards_gallium-radeonsi
	video_cards_siliconmotion
	video_cards_tdfx
	video_cards_tegra
	video_cards_gallium-tegra
	video_cards_vc4
	video_cards_vesa
	video_cards_via
	video_cards_virtualbox
	video_cards_vmware
	video_cards_voodoo
	video_cards_nvidia
"
IUSE="${IUSE_VIDEO_CARDS} ${IUSE_INPUT_DEVICES}"

PDEPEND="
	input_devices_elographics? ( x11-drivers/xf86-input-elographics )
	input_devices_evdev?       ( >=x11-drivers/xf86-input-evdev-2.10.6 )
	input_devices_joystick?    ( >=x11-drivers/xf86-input-joystick-1.6.3 )
	input_devices_libinput?    ( >=x11-drivers/xf86-input-libinput-0.27.1 )
	input_devices_mouse?       ( >=x11-drivers/xf86-input-mouse-1.9.3 )
	input_devices_tslib?       ( x11-drivers/xf86-input-tslib )
	input_devices_vmmouse?     ( x11-drivers/xf86-input-vmmouse )
	input_devices_void?        ( x11-drivers/xf86-input-void )
	input_devices_synaptics?   ( x11-drivers/xf86-input-synaptics )
	input_devices_wacom?       ( >=x11-drivers/xf86-input-wacom-0.36.0-r2 )

	video_cards_amdgpu?        ( >=x11-drivers/xf86-video-amdgpu-18.0.1 )
	video_cards_ast?           ( x11-drivers/xf86-video-ast )
	video_cards_dummy?         ( x11-drivers/xf86-video-dummy )
	video_cards_fbdev?         ( >=x11-drivers/xf86-video-fbdev-0.5.0 )
	video_cards_freedreno?     ( >=x11-base/xorg-server-${PV}[glamor] )
	video_cards_geode?         ( x11-drivers/xf86-video-geode )
	video_cards_glint?         ( >=x11-drivers/xf86-video-glint-1.2.9 )

	video_cards_mga?           ( >=x11-drivers/xf86-video-mga-1.6.5 )
	video_cards_nouveau?       ( >=x11-drivers/xf86-video-nouveau-1.0.13 )
	video_cards_nv?            ( >=x11-drivers/xf86-video-nv-2.1.21 )
	video_cards_omap?          ( >=x11-drivers/xf86-video-omap-0.4.5 )
	video_cards_qxl?           ( x11-drivers/xf86-video-qxl )
	video_cards_nvidia?        ( x11-drivers/nvidia-drivers )
	video_cards_r128?          ( >=x11-drivers/xf86-video-r128-6.10.2 )
	video_cards_radeon?        ( >=x11-drivers/xf86-video-ati-18.0.1-r1 )
	video_cards_gallium-radeonsi? ( >=x11-drivers/xf86-video-ati-18.0.1-r1[glamor] )
	video_cards_radeonsi?      ( >=x11-drivers/xf86-video-ati-18.0.1-r1[glamor] )
	video_cards_siliconmotion? ( >=x11-drivers/xf86-video-siliconmotion-1.7.9 )
	video_cards_tdfx?          ( >=x11-drivers/xf86-video-tdfx-1.4.7 )
	video_cards_gallium-tegra? ( >=x11-base/xorg-server-${PV}[glamor] )
	video_cards_tegra?         ( >=x11-base/xorg-server-${PV}[glamor] )
	video_cards_vc4?           ( >=x11-base/xorg-server-${PV}[glamor] )
	video_cards_vesa?          ( x11-drivers/xf86-video-vesa )
	video_cards_via?           ( x11-drivers/xf86-video-openchrome )
	video_cards_virtualbox?    ( || (
		x11-drivers/xf86-video-vbox
		>=x11-drivers/xf86-video-virtualbox-5.1.14
	) )
	video_cards_vmware?        ( >=x11-drivers/xf86-video-vmware-13.3.0 )
	video_cards_voodoo?        ( x11-drivers/xf86-video-voodoo )
	video_cards_gallium-iris?  ( !x11-drivers/xf86-video-intel )
	video_cards_i915?          ( x11-drivers/xf86-video-intel )
	!video_cards_i915?         ( !x11-drivers/xf86-video-intel )
	video_cards_i965?          ( >=x11-base/xorg-server-${PV}[glamor] )
	!x11-drivers/xf86-input-citron
	!x11-drivers/xf86-video-apm
	!x11-drivers/xf86-video-ark
	!x11-drivers/xf86-video-chips
	!x11-drivers/xf86-video-cirrus
	!x11-drivers/xf86-video-cyrix
	!x11-drivers/xf86-video-i128
	!x11-drivers/xf86-video-i740
	!x11-drivers/xf86-video-impact
	!x11-drivers/xf86-video-mach64
	!x11-drivers/xf86-video-neomagic
	!x11-drivers/xf86-video-newport
	!x11-drivers/xf86-video-nsc
	!x11-drivers/xf86-video-rendition
	!x11-drivers/xf86-video-s3
	!x11-drivers/xf86-video-s3virge
	!x11-drivers/xf86-video-savage
	!x11-drivers/xf86-video-sis
	!x11-drivers/xf86-video-sisusb
	!x11-drivers/xf86-video-sunbw2
	!x11-drivers/xf86-video-suncg14
	!x11-drivers/xf86-video-suncg3
	!x11-drivers/xf86-video-suncg6
	!x11-drivers/xf86-video-sunffb
	!x11-drivers/xf86-video-sunleo
	!x11-drivers/xf86-video-suntcx
	!x11-drivers/xf86-video-tga
	!x11-drivers/xf86-video-trident
	!x11-drivers/xf86-video-tseng
	!<x11-drivers/xf86-input-evdev-2.10.4
"

# This is no longer a Linux-based keyboard driver:

RDEPEND="
	!x11-drivers/xf86-input-keyboard
"
