icon_sizes = ['16', '24', '32', '48', '64', '128', '512']

foreach i : icon_sizes
  install_data(
    join_paths('icons', i, meson.project_name() + '.png'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
  )
endforeach
