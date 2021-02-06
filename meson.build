project(
    'com.github.aharotias2.tatam',
    'vala', 'c',
    version: '1.0.0'
)

posix_dep = meson.get_compiler('vala').find_library('posix')
libm_dep = meson.get_compiler('c').find_library('libm')

executable(
    'tatam',
    'src/tatam.vala',
    'src/consts/enums.vala',
    'src/consts/Text.vala',
    'src/consts/OptionKey.vala',
    'src/consts/IconNames.vala',
    'src/consts/ProgramName.vala',
    'src/consts/Error.vala',
    'src/consts/DefaultCss.vala',
    'src/consts/StyleClass.vala',
    'src/AppBase.vala',
    'src/utils/FilePathUtils.vala',
    'src/utils/RGBAUtils.vala',
    'src/utils/NumberUtils.vala',
    'src/utils/StringUtils.vala',
    'src/utils/TimeUtils.vala',
    'src/utils/PixbufUtils.vala',
    'src/utils/Files.vala',
    'src/utils/Dialogs.vala',
    'src/facade/GstPlayer.vala',
    'src/adapters/GstSampleAdapter.vala',
    'src/adapters/FileInfoAdapter.vala',
    'src/widgets/ArtworkView.vala',
    'src/widgets/Controller.vala',
    'src/widgets/HeaderBar.vala',
    'src/widgets/Finder.vala',
    'src/widgets/PlaylistItem.vala',
    'src/widgets/Stack.vala',
    'src/widgets/PlaylistBox.vala',
    'src/widgets/Sidebar.vala',
    'src/widgets/FinderItem.vala',
    'src/widgets/PlaylistDrawingArea.vala',
    'src/widgets/FinderToolbar.vala',
    'src/widgets/Window.vala',
    'src/atoms/Hex.vala',
    'src/atoms/SmallTime.vala',
    'src/models/Tracker.vala',
    'src/models/Options.vala',
    'src/models/FileInfo.vala',
    'src/strategy/MetadataReader.vala',
    'src/strategy/StringJoiner.vala',
    'src/strategy/DirectoryReader.vala',
    dependencies: [
        dependency('gee-0.8'),
        dependency('gstreamer-1.0'),
        dependency('gtk+-3.0'),
        dependency('gdk-3.0'),
        dependency('json-glib-1.0'),
        posix_dep,
        libm_dep
    ],
    install: true
)
install_data('tatam.desktop', install_dir: 'share/applications')
install_data('tatam.png', install_dir: 'share/pixmaps')
