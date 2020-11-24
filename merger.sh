#!/bin/bash

# Merge S-P by YukoSky @ Treble-Experience
# License: GPL3

echo ""
echo "##############################"
echo "#                            #"
echo "# S(EXT)-P Merger by YukoSky #"
echo "#         v1.3-Fix           #"
echo "#                            #"
echo "##############################"
echo ""

### Initial vars
LOCALDIR=`cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd`
FE="$LOCALDIR/tools/firmware_extractor"

## Mount Point vars for system_new
SYSTEM_NEW_DIR="$LOCALDIR/system_new"
SYSTEM_NEW_IMAGE="$LOCALDIR/system_new.img"

## Mount Point vars for system
SYSTEM_DIR="$LOCALDIR/system"
SYSTEM_IMAGE="$LOCALDIR/system.img"

## Mount Point vars for product
PRODUCT_DIR="$LOCALDIR/product"
PRODUCT_IMAGE="$LOCALDIR/product.img"
PRODUCT=false

## Mount Point vars for odm
ODM_DIR="$LOCALDIR/odm"
ODM_IMAGE="$LOCALDIR/odm.img"
ODM=false

## Mount Point vars for opproduct
OPPRODUCT_DIR="$LOCALDIR/opproduct"
OPPRODUCT_IMAGE="$LOCALDIR/opproduct.img"
OPPRODUCT=false

## Mount Point vars for system_ext
SYSTEM_EXT_DIR="$LOCALDIR/system_ext"
SYSTEM_EXT_IMAGE="$LOCALDIR/system_ext.img"
SYSTEM_EXT=false

## Mount Point vars for vendor
VENDOR_DIR="$LOCALDIR/vendor"
VENDOR_IMAGE="$LOCALDIR/vendor.img"
OVERLAYS_VENDOR=false

CREDITS() {
   # Just a comment in build.prop
   echo "" >> build.prop
   echo "#############################" >> build.prop
   echo "# Merged by S(EXT)-P Merger #" >> build.prop
   echo "#        By YukoSky         #" >> build.prop
   echo "#############################" >> build.prop
   echo "" >> build.prop
}

usage() {
    echo "Usage: $0 <Path to firmware>"
    echo -e "\tPath to firmware: the zip!"
    echo -e "\t--ext: Merge /system_ext partition in the system"
    echo -e "\t--odm: Merge /vendor/odm partition in the system (Recommended on Android 11)"
    echo -e "\t--product: Merge /product partition in the system"
    echo -e "\t--overlays: Take the overlays from /vendor and put them in a temporary folder and compress at the end of the process"
    echo -e "\t--opproduct: Merge /oneplus partition in the system (OxygenOS only)"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --product)
    PRODUCT=true
    shift
    ;;
    --odm)
    ODM=true
    shift
    ;;
    --ext)
    SYSTEM_EXT=true
    shift
    ;;
    --opproduct)
    OPPRODUCT=true
    shift
    ;;
    --overlays)
    OVERLAYS_VENDOR=true
    shift
    ;;
    --help|-h|-?)
    usage
    exit
    ;;
    *)
    POSITIONAL+=("$1")
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional

if [ ! -f "$FE/extractor.sh" ]; then
   echo "-> Firmware Extractor isn't cloned or don't exists! Exit 1."
   exit 1
fi

if [[ ! -n $1 ]]; then
    echo "-> ERROR!"
    echo " - Enter all needed parameters"
    usage
    exit
fi

echo "-> Starting the process..."
cd $FE; chmod +x -R *
bash $FE/extractor.sh "$1" "$LOCALDIR"

# system.img
echo "-> Check mount/etc for system.img"
if [ -f "$SYSTEM_IMAGE" ]; then
   # Check for AB/Aonly in system
   if [ -d "$SYSTEM_DIR" ]; then
      if [ -d "$SYSTEM_DIR/dev/" ]; then
         echo " - SAR Mount detected in system, force umount!"
         sudo umount "$SYSTEM_DIR/"
      else
         if [ -d "$SYSTEM_DIR/etc/" ]; then
            echo " - Aonly Mount detected in system, force umount!"
            sudo umount "$SYSTEM_DIR/"
         fi
      fi
   fi
   echo " - Done: system"
else
   echo " - system don't exists, exit 1."
   exit 1
fi

# system_new.img
echo "-> Check mount/etc for system_new"
if [ -f "$SYSTEM_NEW_IMAGE" ]; then
   # Check for AB/Aonly in system_new
   if [ -d "$SYSTEM_NEW_DIR" ]; then
      if [ -d "$SYSTEM_NEW_DIR/dev/" ]; then
         echo " - SAR Mount detected in system_new, force umount!"
         sudo "$SYSTEM_NEW_DIR/"
      else
         if [ -d "$SYSTEM_NEW_DIR/etc/" ]; then
            echo " - Aonly Mount detected in system_new, force umount!"
            sudo "$SYSTEM_NEW_DIR/"
         fi
      fi
   fi
   echo " - Delete: system_new and mount point"
   sudo rm -rf $SYSTEM_NEW_IMAGE $SYSTEM_NEW_DIR/
   sudo dd if=/dev/zero of=$SYSTEM_NEW_IMAGE bs=4k count=2048576 > /dev/null 2>&1
   sudo tune2fs -c0 -i0 $SYSTEM_NEW_IMAGE > /dev/null 2>&1
   sudo mkfs.ext4 $SYSTEM_NEW_IMAGE > /dev/null 2>&1
   if [ ! -f "$SYSTEM_NEW_IMAGE" ]; then
      echo " - system_new don't exists, exit 1."
      exit 1
   fi
else
   echo " - system_new.img don't exists, create one..."
   sudo rm -rf $SYSTEM_NEW_IMAGE $SYSTEM_NEW_DIR/
   sudo dd if=/dev/zero of=$SYSTEM_NEW_IMAGE bs=4k count=2048576 > /dev/null 2>&1
   sudo tune2fs -c0 -i0 $SYSTEM_NEW_IMAGE > /dev/null 2>&1
   sudo mkfs.ext4 $SYSTEM_NEW_IMAGE > /dev/null 2>&1
   if [ ! -f "$SYSTEM_NEW_IMAGE" ]; then
      echo " - system_new don't exists, exit 1."
      exit 1
   fi
   echo " - Done: system_new"
fi

# product.img
if [ "$PRODUCT" == true ]; then
   echo "-> Check mount/etc for product"
   if [ -f "$PRODUCT_IMAGE" ]; then
     # Check if product is mounted
     if [ -d "$PRODUCT_DIR" ]; then
        if [ -d "$PRODUCT_DIR/etc/" ]; then
           echo " - Mount detected in product, force umount!"
           sudo umount "$PRODUCT_DIR/"
        fi
     fi
     echo " - Done: product"
   else
     echo " - Product image don't exists!"
   fi
else
   echo "-> Warning: Product option was not selected"
fi

# vendor.img
if [ $OVERLAYS_VENDOR == true ]; then
   echo "-> Check mount/etc for vendor"
   if [ -f "$VENDOR_IMAGE" ]; then
     # Check if product is mounted
     if [ -d "$VENDOR_DIR" ]; then
        if [ -d "$VENDOR_DIR/etc/" ]; then
           echo " - Mount detected in vendor, force umount!"
           sudo umount "$VENDOR_DIR/"
        fi
     fi
     echo " - Done: vendor"
   else
     echo " - Vendor image don't exists!"
   fi
else
   echo "-> Warning: Extract overlays from vendor option was not selected"
fi

# odm.img
if [ "$ODM" == true ]; then
   echo "-> Check mount/etc for odm"
   if [ -f "$ODM_IMAGE" ]; then
      # Check if odm is mounted
      if [ -d "$ODM_DIR" ]; then
         if [ -d "$ODM_DIR/etc/" ]; then
           echo " - Mount detected in odm, force umount!"
           sudo umount "$ODM_DIR/"
         fi
      fi
      echo " - Done: odm"
   else
      echo " - odm don't exists, be careful!"
   fi
else
   echo "-> Warning: ODM option was not selected"
fi

# opproduct.img
if [ "$OPPRODUCT" == true ]; then
   echo "-> Check mount/etc for opproduct"
   if [ -f "$OPPRODUCT_IMAGE" ]; then
      # Check if product is mounted
      if [ -d "$OPPRODUCT_DIR" ]; then
         if [ -d "$OPPRODUCT_DIR/etc/" ]; then
            echo " - Mount detected in opproduct, force umount!"
            sudo umount "$OPPRODUCT_DIR/"
         fi
      fi
      echo " - Done: opproduct"
   else
      echo " - opproduct don't exists, be careful!"
   fi
else
   echo "-> Warning: OP option was not selected"
fi

# system_ext.img
if [ "$SYSTEM_EXT" == true ]; then
   echo "-> Check mount/etc for system_ext"
   if [ -f "$SYSTEM_EXT_IMAGE" ]; then
      # Check if product is mounted
      if [ -d "$SYSTEM_EXT_DIR" ]; then
         if [ -d "$SYSTEM_EXT_DIR/etc/" ]; then
            echo " - Mount detected in system_ext, force umount!"
            sudo umount "$SYSTEM_EXT_DIR/"
         fi
      fi
      echo " - Done: system_ext"
   else
      echo " - system_ext don't exists, be careful!"
   fi
else
   echo "-> Warning: System Ext option was not selected"
fi

echo "-> Starting process!"

echo " - Mount system"
if [ ! -d "$SYSTEM_DIR/" ]; then
   mkdir $SYSTEM_DIR
fi
sudo mount -o ro $SYSTEM_IMAGE $SYSTEM_DIR/

echo " - Mount system_new"
if [ ! -d "$SYSTEM_NEW_DIR/" ]; then
   mkdir $SYSTEM_NEW_DIR
fi
sudo mount -o loop $SYSTEM_NEW_IMAGE $SYSTEM_NEW_DIR/

if [ "$PRODUCT" == true ]; then
   if [ -f "$PRODUCT_IMAGE" ]; then
      echo " - Mount product"
      if [ ! -d "$PRODUCT/" ]; then
         mkdir $PRODUCT_DIR
      fi
      sudo mount -o ro $PRODUCT_IMAGE $PRODUCT_DIR/
   fi
fi

if [ "$ODM" == true ]; then
   if [ -f "$ODM_IMAGE" ]; then
      echo " - Mount odm"
      if [ ! -d "$ODM_DIR/" ]; then
         mkdir $ODM_DIR
      fi
      sudo mount -o ro $ODM_IMAGE $ODM_DIR/
   fi
fi

if [ "$OPPRODUCT" == true ]; then
   if [ -f "$OPPRODUCT_IMAGE" ]; then
      echo " - Mount opproduct"
      if [ ! -d "$OPPRODUCT_DIR/" ]; then
         mkdir $OPPRODUCT_DIR
      fi
      sudo mount -o ro $OPPRODUCT_IMAGE $OPPRODUCT_DIR/
   fi
fi

if [ "$SYSTEM_EXT" == true ]; then
  if [ -f "$SYSTEM_EXT_IMAGE" ]; then
    echo " - Mount system_ext"
    if [ ! -d "$SYSTEM_EXT_DIR/" ]; then
      mkdir $SYSTEM_EXT_DIR
    fi
    sudo mount -o ro $SYSTEM_EXT_IMAGE $SYSTEM_EXT_DIR/
  fi
fi

if [ "$OVERLAYS_VENDOR" == true ]; then
  if [ -f "$VENDOR_IMAGE" ]; then
    echo " - Mount vendor"
    if [ ! -d "$VENDOR_DIR/" ]; then
       mkdir $VENDOR_DIR
    fi
    sudo mount -o ro $VENDOR_IMAGE $VENDOR_DIR
  fi
fi

echo "-> Copy system files to system_new"
cp -v -r -p $SYSTEM_DIR/* $SYSTEM_NEW_DIR/ > /dev/null 2>&1 && sync
if [ -d "$SYSTEM_NEW_DIR/dev/" ]; then
   cd $LOCALDIR/system_new/system/
   CREDITS
else
   if [ ! -f "$SYSTEM_NEW_DIR/build.prop" ]; then
      echo "-> Are you sure this is a Android image? Exit"
      exit 1
   fi
   cd $SYSTEM_NEW_DIR
   CREDITS
fi
echo "-> Umount system"
umount $SYSTEM_DIR/
cd $LOCALDIR

if [ "$PRODUCT" == true ]; then
   if [ -f "$PRODUCT_IMAGE" ]; then
      echo "-> Copy product files to system_new"
      if [ -d "$SYSTEM_NEW_DIR/dev/" ]; then
         echo " - Using SAR method"
         cd $LOCALDIR/system_new/
         rm -rf product; cd system; rm -rf product
         mkdir -p product/
         cp -v -r -p $PRODUCT_DIR/* product/ > /dev/null 2>&1
         cd ../
         echo " - Fix symlink in product"
         ln -s /system/product/ product
         sync
         echo " - Fixed"
      else
         if [ ! -f "$SYSTEM_NEW_DIR/build.prop" ]; then
            echo "-> Are you sure this is a Android image? Exit"
            exit 1
         fi
         cd $SYSTEM_NEW_DIR
         rm -rf product
         mkdir product && cd ../
         cp -v -r -p $PRODUCT/* $SYSTEM_NEW/product/ > /dev/null 2>&1 && sync
         cd $LOCALDIR
      fi
   fi
   cd $LOCALDIR
fi

if [ "$PRODUCT" == true ]; then
   if [ -f "$PRODUCT_IMAGE" ]; then
      echo "-> Umount product"
      sudo umount $PRODUCT_DIR/
  fi
fi

if [ "$ODM" == true ]; then
   if [ -f "$ODM_IMAGE" ]; then
     echo "-> Copy odm files to system_new"
     if [ -d "$SYSTEM_NEW_DIR/dev/" ]; then
        echo " - Using SAR method"
        cd $LOCALDIR/system_new/
        rm -rf odm; cd system; rm -rf odm
        mkdir -p odm/
        cp -v -r -p $ODM_DIR/* odm/ > /dev/null 2>&1
        cd ../
        echo " - Fix symlink in odm"
        ln -s /system/odm/ odm
        sync
        echo " - Fixed"
   else
     if [ ! -f "$SYSTEM_NEW_DIR/build.prop" ]; then
        echo "-> Are you sure this is a Android image? Exit"
        exit 1
     fi
     cd $SYSTEM_NEW_DIR
     rm -rf odm
     mkdir odm && cd ../
     cp -v -r -p $ODM/* $SYSTEM_NEW_DIR/odm/ > /dev/null 2>&1 && sync
     cd $LOCALDIR
   fi
fi
cd $LOCALDIR
fi

if [ "$ODM" == true ]; then
   if [ -f "$ODM_IMAGE" ]; then
     echo "-> Umount odm"
     sudo umount $ODM_DIR/
   fi
fi

if [ "$OPPRODUCT" == true ]; then
   if [ -f "$OPPRODUCT_IMAGE" ]; then
   echo "-> Copy opproduct files to system_new"
      if [ -d "$SYSTEM_NEW_DIR/dev/" ]; then
         echo " - Using SAR method"
         cd $LOCALDIR/system_new/
         rm -rf oneplus; cd system; rm -rf oneplus
         mkdir -p oneplus/
         cp -v -r -p $OPPRODUCT_DIR/* oneplus/ > /dev/null 2>&1
         cd ../
         echo " - Fix symlink in opproduct"
         ln -s /system/oneplus/ oneplus
         sync
         echo " - Fixed"
   else
      if [ ! -f "$SYSTEM_NEW_DIR/build.prop" ]; then
         echo "-> Are you sure this is a Android image? Exit"
         exit 1
      fi
      cd $SYSTEM_NEW_DIR
      rm -rf oneplus
      mkdir oneplus && cd ../
      cp -v -r -p $OPPRODUCT_DIR/* $SYSTEM_NEW_DIR/oneplus/ > /dev/null 2>&1 && sync
      cd $LOCALDIR
   fi
fi
cd $LOCALDIR
fi

if [ "$OPPRODUCT" == true ]; then
   if [ -f "$OPPRODUCT_IMAGE" ]; then
      echo "-> Umount opproduct"
      sudo umount $OPPRODUCT_DIR/
   fi
fi

if [ "$SYSTEM_EXT" == true ]; then
   if [ -f "$SYSTEM_EXT_IMAGE" ]; then
   echo "-> Copy system_ext files to system_new"
      if [ -d "$SYSTEM_NEW_DIR/dev/" ]; then
         echo " - Using SAR method"
         cd $LOCALDIR/system_new/
         rm -rf system_ext; cd system; rm -rf system_ext
         mkdir -p system_ext/
         cp -v -r -p $SYSTEM_EXT_DIR/* system_ext/ > /dev/null 2>&1
         cd ../
         echo " - Fix symlink in system_ext"
         ln -s /system/system_ext/ system_ext
         sync
         echo " - Fixed"
      else
         if [ ! -f "$SYSTEM_NEW_DIR/build.prop" ]; then
         echo "-> Are you sure this is a Android image? Exit"
         exit 1
      fi
      cd $SYSTEM_NEW_DIR
      rm -rf system_ext
      mkdir system_ext && cd ../
      cp -v -r -p $SYSTEM_EXT/* $SYSTEM_NEW_DIR/system_ext/ > /dev/null 2>&1 && sync
      cd $LOCALDIR
   fi
fi
cd $LOCALDIR
fi

if [ "$SYSTEM_EXT" == true ]; then
   if [ -f "$SYSTEM_EXT_IMAGE" ]; then
      echo "-> Umount system_ext"
      sudo umount $SYSTEM_EXT_DIR/
   fi
fi

echo "-> Umount system_new"
sudo umount $SYSTEM_NEW_DIR/

if [ "$OVERLAYS_VENDOR" == true ]; then
   if [ -f "$VENDOR_IMAGE" ]; then
      # Check if have anything in vendor
      if [ -d "$VENDOR_DIR/overlay" ]; then
         # If yes we'll copy overlays
         echo " - Copying overlays from vendor..."
         mkdir -p "$LOCALDIR/vendorOverlays"
         cp -v -r -p $VENDOR_DIR/overlay/* $LOCALDIR/vendorOverlays/ > /dev/null 2>&1
         zip -r vendorOverlays.zip "$LOCALDIR/vendorOverlays" > /dev/null 2>&1
         echo " - Process of copying vendor overlays is done"
         rm -rf $LOCALDIR/vendorOverlays/
      fi
   fi
fi

if [ "$OVERLAYS_VENDOR" == true ]; then
   if [ -f "$VENDOR_IMAGE" ]; then
      echo "-> Umount vendor"
      sudo umount $VENDOR_DIR/
   fi
fi

echo "-> Remove tmp folders and files"
sudo rm -rf $SYSTEM_DIR $SYSTEM_NEW_DIR $PRODUCT_DIR $SYSTEM_IMAGE $PRODUCT_IMAGE $SYSTEM_EXT_DIR $SYSTEM_EXT_IMAGE $OPPRODUCT_DIR $OPPRODUCT_IMAGE $ODM_DIR $ODM_IMAGE $VENDOR_DIR $VENDOR_IMAGE

echo " - Compacting..."
mv system_new.img system.img
zip system.img.zip system.img

sudo rm -rf *.img

echo "-> Done, just run with url2GSI.sh"
