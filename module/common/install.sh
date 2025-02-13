echo -n $LIBPATCH > $MODPATH/libpatch.txt

ui_print "    Copying lib files..."

# Install both libraries for 32-bit systems
cp_ch -n $MODPATH/common/files/libv4a_re_$ABI32.so $MODPATH$LIBDIR/lib/soundfx/libv4a_re.so
cp_ch -n $MODPATH/common/files/libv4aidl_re_$ABI32.so $MODPATH$LIBDIR/lib/soundfx/libv4aidl_re.so

# Install both libraries for 64-bit systems
if [ "$IS64BIT" ]; then
  cp_ch -n $MODPATH/common/files/libv4a_re_$ABI.so $MODPATH$LIBDIR/lib64/soundfx/libv4a_re.so
  cp_ch -n $MODPATH/common/files/libv4aidl_re_$ABI.so $MODPATH$LIBDIR/lib64/soundfx/libv4aidl_re.so
fi

ui_print "    Patching audio_effects config files"
CFGS="$(find /odm /system /vendor -type f -name "*audio_effects*.conf" -o -name "*audio_effects*.xml")"

for OFILE in ${CFGS}; do
  FILE="$MODPATH$(echo $OFILE | sed "s|^/vendor|/system/vendor|g")"
  cp_ch -n $OFILE $FILE
  
  case $FILE in
    *.conf)
        # Remove any previous instances
        sed -i "/v4a_standard_re {/,/}/d" $FILE
        sed -i "/v4a_re {/,/}/d" $FILE
        sed -i "/v4a_standard_aidl {/,/}/d" $FILE
        sed -i "/v4a_aidl {/,/}/d" $FILE

        # Add new effect configurations for both standard and AIDL versions
        sed -i "s/^effects {/effects {\n  v4a_standard_re {\n    library v4a_re\n    uuid 90380da3-8536-4744-a6a3-5731970e640f\n  }\n  v4a_standard_aidl {\n    library v4a_aidl\n    uuid 23c45d71-901f-4a9c-ae57-7e2f2f94621f\n  }/g" $FILE

        # Add library paths for both versions
        sed -i "s/^libraries {/libraries {\n  v4a_re {\n    path $LIBPATCH\/lib\/soundfx\/libv4a_re.so\n  }\n  v4a_aidl {\n    path $LIBPATCH\/lib\/soundfx\/libv4aidl_re.so\n  }/g" $FILE
        ;;
    *.xml)
        # Remove old configurations
        sed -i "/v4a_standard_re/d" $FILE
        sed -i "/v4a_re/d" $FILE
        sed -i "/v4a_standard_aidl/d" $FILE
        sed -i "/v4a_aidl/d" $FILE

        # Add new libraries
        sed -i "/<libraries>/ a\        <library name=\"v4a_re\" path=\"libv4a_re.so\"\/>" $FILE
        sed -i "/<libraries>/ a\        <library name=\"v4a_aidl\" path=\"libv4aidl_re.so\"\/>" $FILE

        # Add new effects
        sed -i "/<effects>/ a\        <effect name=\"v4a_standard_re\" library=\"v4a_re\" uuid=\"90380da3-8536-4744-a6a3-5731970e640f\"\/>" $FILE
        sed -i "/<effects>/ a\        <effect name=\"v4a_standard_aidl\" library=\"v4a_aidl\" uuid=\"23c45d71-901f-4a9c-ae57-7e2f2f94621f\"\/>" $FILE
        ;;
  esac
done
