#! /bin/bash
cp ../pubspec.yaml ../pubspec.yaml.orig
cat << EOF >> ../pubspec.yaml
  # TODO:
  #   Fonts are taking too much space. Need to find a smaller set or wait
  #   for this issue to be resolved to only include it for Linux:
  #   https://github.com/flutter/flutter/issues/65065 
  fonts:
    - family: "Cylonix_Noto"
      fonts:
        - asset: packages/sase_app_ui/assets/fonts/NotoSansCJK-Regular.ttc
EOF
