#!/usr/bin/env fish

source ./_functions.fish

set iconpack_name "System UIcons"
set version_file version.system-uicons.txt
set iconpack_version (cat $version_file | string trim)

echo "Preparing to build Stream Deck icon pack \"$iconpack_name\""
echo

if not ask_for_confirmation --question "Version $iconpack_version, correct?"
  set iconpack_version (math $iconpack_version + 0.1)
  if ask_for_confirmation --question "Bump version to $iconpack_version?"
    echo "- Bumping version to $iconpack_version"
    echo $iconpack_version > $version_file
    git commit -m "[CHG] Bumps version" $version_file
  else
    echo "Exiting"
    exit 1
  end
end


# Setup folders
set iconpack_folder_name (slugify "$iconpack_name")".sdIconPack"
set build_folder (pwd)"/build"
set target_folder "$build_folder/$iconpack_folder_name"
set icon_folder "$target_folder/icons"
set src_folder (pwd)"/src"
set tmp_folder (pwd)"/tmp"
set dist_folder (pwd)"/dist/streamdeck-iconpack-system-uicons/$iconpack_folder_name"

echo "- Setting up folders"
rm -rf "$build_folder" "$tmp_folder" "$src_folder" >/dev/null 2>&1
mkdir -p "$target_folder" "$icon_folder" "$tmp_folder" "$src_folder"


echo "- Downloading icons from https://systemuicons.com/"
set zip_file "$tmp_folder/system_icons.zip"
curl --silent "https://systemuicons.com/images/System%20UIcons.zip" -o "$zip_file"
unzip -jq "$zip_file" -d "$src_folder"


echo "- Writing SVG build files"
cp (ls "$src_folder"/*.svg) "$icon_folder/"
sd '"currentColor"' '"#fff"' (ls "$icon_folder"/*.svg)

set extra_icons_red $src_folder/bell_disabled.svg \
                    $src_folder/camera_noflash_alt.svg \
                    $src_folder/camera_noflash.svg \
                    $src_folder/cloud_disconnect.svg \
                    $src_folder/cross.svg \
                    $src_folder/cross_circle.svg \
                    $src_folder/heart_remove.svg \
                    $src_folder/eye_no.svg \
                    $src_folder/microphone_disabled.svg \
                    $src_folder/microphone_muted.svg \
                    $src_folder/record.svg \
                    $src_folder/volume_disabled.svg \
                    $src_folder/volume_muted.svg \
                    $src_folder/warning_circle.svg \
                    $src_folder/warning_hex.svg \
                    $src_folder/warning_triangle.svg \
                    $src_folder/wifi_none.svg
for F in $extra_icons_red
  set --local new_name (string replace ".svg" "__red.svg" (basename "$F"))
  cp "$F" "$icon_folder/$new_name"
end
sd '"currentColor"' '"#f00"' (ls "$icon_folder"/*__red.svg)

set extra_icons_green $src_folder/info_circle.svg \
                      $src_folder/home_check.svg \
                      $src_folder/check_circle.svg \
                      $src_folder/check_circle_outside.svg \
                      $src_folder/checkbox_checked.svg \
                      $src_folder/clipboard_check.svg
for F in $extra_icons_green
  set --local new_name (string replace ".svg" "__green.svg" (basename "$F"))
  cp "$F" "$icon_folder/$new_name"
end
sd '"currentColor"' '"#0f0"' (ls "$icon_folder"/*__green.svg)


echo "- Converting SVG build files to PNG"
set icon_files (ls "$icon_folder"/*.svg)
for svg_file in $icon_files
  convert_svg_to_png --file $svg_file
end


echo "- Deleting SVG build files"
rm $icon_files


echo "- Building icons list"
png_list_to_json --folder "$icon_folder" > "$target_folder/icons.json"


echo "- Building manifest"
echo "{
  \"Author\": \"Carlo Zottmann (icon pack), Corey Ginnivan (original System UIcons)\",
  \"Description\": \"$iconpack_name\",
  \"Name\": \"$iconpack_name\",
  \"URL\": \"https://streamdeck-iconpacks.czm.io\",
  \"Version\": \"$iconpack_version\",
  \"Icon\": \"icons/create.png\",
  \"Tags\": \"\"
}" > "$target_folder/manifest.json"


if ask_for_confirmation --question "Copy pack into SD IconPacks/ folder?  (This will overwrite an existing $iconpack_folder_name pack!)"
  set sd_data_folder "$HOME/Library/Application Support/com.elgato.StreamDeck/IconPacks/$iconpack_folder_name"
  echo "- Copying icon pack to $sd_data_folder"
  rm -rf "$sd_data_folder"
  cp -R "$target_folder" "$sd_data_folder"
end

if ask_for_confirmation --question "Copy pack into dist/ folder?"
  echo "- Copying icon pack to $dist_folder"
  rm -rf $dist_folder/* >/dev/null 2>&1
  cp -R $target_folder/* $dist_folder/
  cp $dist_folder/../LICENSE.md $dist_folder/
end

# TODO: Ask to update website

echo "- Cleaning up working folders"
rm -rf "$build_folder" "$tmp_folder" "$src_folder" >/dev/null 2>&1

echo "- Done!"
