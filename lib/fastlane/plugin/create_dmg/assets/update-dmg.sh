#!/bin/sh

set -Eeo pipefail

# A path to the template DMG file
TEMPLATE_DMG=
# Source file to add to DMG
SOURCE_FILE=
# A path Output DMG
OUTPUT_DMG=
# Codesign identity if passed
CODE_SIGN_IDENTITY=
# hdiutil verbosity level
HDIUTIL_VERBOSITY=

# Mount point - random UUID to avoid conflicts
DMG_MOUNT_POINT=$(uuidgen)
# A path to a temporary (writable) DMG file
DMG_TEMP="$(mktemp).dmg"

# Maximum attempts to perform before trying force DMG detachment.
MAXIMUM_UNMOUNTING_ATTEMPTS=3

# Outputs script usage
function usage() {
  cat <<EOHELP

Updates file or folder in template DMG file.

Usage: $(basename $0) [options] --source <source_folder> --template_dmg <template.dmg> --output_dmg <output_name.dmg>

The <source_folder> will be copied into the disk image.

Options:
  --source
      Source file or folder to add into the new DMG.
  --template-dmg
      Path to the template disk image file.
  --output-dmg
      Path to the resulting disk image file.
  --code-sign-identity
      Code sign idenity to sign the resulting DMG.
  --hdiutil-verbose
      Execute hdiutil in verbose mode.
  --hdiutil-quiet
      Execute hdiutil in quiet mode.
  -h, --help
      display this help screen

EOHELP
  exit 0
}

# Detaches mounted DMG
function unmount() {
  DEV_NAME=$1
  DMG_MOUNT_POINT=$2

  if [[ ! -z "${DMG_MOUNT_POINT}" && ! -d "${DMG_MOUNT_POINT}" ]]; then
    # DMG is not mounted
    break
  fi

  # Unmount
  unmounting_attempts=0
  until
    echo "⏏️  Unmount '${DEV_NAME}'"
    (( unmounting_attempts++ ))
    hdiutil detach "${DEV_NAME}"
    exit_code=$?
    (( exit_code ==  0 )) && break            # nothing goes wrong
    (( exit_code != 16 )) && exit $exit_code  # exit with the original exit code
    # The above statement returns 1 if test failed (exit_code == 16).
    #   It can make the code in the {do... done} block to be executed
  do
    (( unmounting_attempts == MAXIMUM_UNMOUNTING_ATTEMPTS )) && exit 16  # patience exhausted, exit with code EBUSY
    echo "🚦 Wait a moment..."
    sleep $(( 1 * (2 ** unmounting_attempts) ))
  done
  unset unmounting_attempts

  if [[ ! -z "${DMG_MOUNT_POINT}" && -d "${DMG_MOUNT_POINT}" ]]; then
    echo " ⏏️ Unmount '${DEV_NAME}' at '${DMG_MOUNT_POINT}' with force"
    hdiutil detach "${DEV_NAME}" -force
  fi
}

# Check if min parameters count is set.
if [[ -z "$6" ]]; then
  echo "🙅 Not enough arguments. Run '$(basename $0) --help' for help."
  exit 1
fi

# Argument parsing.
while [[ "${1:0:1}" = "-" ]]; do
  case $1 in
    --template-dmg)
      TEMPLATE_DMG="$2"
      shift; shift;;
    --source)
      SOURCE_FILE="$2"
      shift; shift;;
    --output-dmg)
      OUTPUT_DMG="$2"
      shift; shift;;
    --code-sign-identity)
      CODE_SIGN_IDENTITY="$2"
      shift; shift;;
    --hdiutil-verbose)
      HDIUTIL_VERBOSITY='-verbose'
      shift;;
    --hdiutil-quiet)
      HDIUTIL_VERBOSITY='-quiet'
      shift;;
    --help)
      usage;;
    -*)
      echo "🤨 Unknown option: $1. Run 'create-dmg --help' for help."
      exit 1;;
  esac
done

# Check codesing.
CODE_SIGN_FINGERPRINT_ID=
if [[ ! -z "${CODE_SIGN_IDENTITY}" ]]; then
  CODE_SIGN_FINGERPRINT_ID=$(security find-identity -v -p codesigning | grep -E "${CODE_SIGN_IDENTITY}" | awk '{ print $2; exit }')
  if [[ -z "${CODE_SIGN_FINGERPRINT_ID}" ]]; then
    echo "❌ Codesign identity '${CODE_SIGN_IDENTITY}' was not found in the Keychain. Import the codesign certificate '${CODE_SIGN_IDENTITY}' with private key into your Keychain and try again."
    exit 1
  fi
fi

# Returns dev/ name from mounting point.
function get_device_name {
  DMG_MOUNT_POINT=$1
  DEV_NAME=$(hdiutil info | egrep '^/dev/' | grep "$DMG_MOUNT_POINT" | sed 1q | awk '{ print $1 }' || echo '')
  echo "${DEV_NAME}"
}

# Remove temp DMG if any.
if [[ -f "${DMG_TEMP}" ]]; then
  echo "🧹 Clean-up"
  rm -Rf "${DMG_TEMP}"
fi

# Convert DMG template to RW format.
echo "🔄 Convert template '${TEMPLATE_DMG}' to writable disk image at '${DMG_TEMP}'"
hdiutil convert "${TEMPLATE_DMG}" -format UDRW -o "${DMG_TEMP}" ${HDIUTIL_VERBOSITY}

# Calculate max resulting image size.
SOURCE_SIZE=$(du -sm "${SOURCE_FILE}" | awk '{ print $1 }')
TEMPLATE_SIZE=$(du -sm "${TEMPLATE_DMG}" | awk '{ print $1 }')
DISK_IMAGE_SIZE=$(expr $SOURCE_SIZE '+' $SOURCE_SIZE '*' 10 '/' 100 '+' 10 + $TEMPLATE_SIZE)
# Increase actual size by 10% and add extra 10MB on top.
echo "↔️  Resize '${DMG_TEMP}' to ${DISK_IMAGE_SIZE}MB"
hdiutil resize "${DMG_TEMP}" -size ${DISK_IMAGE_SIZE}m ${HDIUTIL_VERBOSITY}

# Try unmount dmg if it was mounted previously.
DEV_NAME=$(get_device_name "${DMG_MOUNT_POINT}")
if [[ ! -z "${DEV_NAME}" ]]; then
  unmount "${DEV_NAME}" "${DMG_MOUNT_POINT}"
fi

# Mount writable disk image.
echo "🧗 Mount '${DMG_TEMP}' at ${DMG_MOUNT_POINT}"
hdiutil attach -readwrite -noverify -noautoopen -nobrowse "${DMG_TEMP}" -mountpoint "${DMG_MOUNT_POINT}" ${HDIUTIL_VERBOSITY}
DEV_NAME=$(get_device_name "${DMG_MOUNT_POINT}")
echo "💾 Device name: ${DEV_NAME}"

# Copy source to DMG.
echo "♊️ Copy '${SOURCE_FILE}' to '${DMG_MOUNT_POINT}'"
DESTINATION_FILE="${DMG_MOUNT_POINT}"/$(basename -- "${SOURCE_FILE}")
if [[ -f "${DESTINATION_FILE}" || -d "${DESTINATION_FILE}" ]]; then
  echo "🧹 Remove existing ${DESTINATION_FILE}"
  rm -rf "${DESTINATION_FILE}"
fi
ditto --rsrc --extattr "${SOURCE_FILE}" "${DMG_MOUNT_POINT}"/$(basename -- "${SOURCE_FILE}")

# Flush disk cache to prevent "Resource busy" failures.
sync

# Unmount updated disk image.
unmount "${DEV_NAME}" "${DMG_MOUNT_POINT}"

# Convert DMG to compressed RO format.
if [[  -f "${OUTPUT_DMG}" ]]; then
  echo "🧹 Remove existing ${OUTPUT_DMG}"
  rm -Rf "${OUTPUT_DMG}"
fi
hdiutil convert "${DMG_TEMP}" -format UDZO -imagekey zlib-level=9 -o "${OUTPUT_DMG}" ${HDIUTIL_VERBOSITY}

# Sign DMG if needed.
if [[ ! -z "${CODE_SIGN_IDENTITY}" ]]; then
  echo "✍️ Codesign '${OUTPUT_DMG}'"
  codesign -fv -s "${CODE_SIGN_FINGERPRINT_ID}" "${OUTPUT_DMG}"
fi

# Verify DMG.
echo "🧐 Verify '${OUTPUT_DMG}'"
hdiutil verify "${OUTPUT_DMG}" ${HDIUTIL_VERBOSITY}

# Remove temp DMG.
if [[ -f "${DMG_TEMP}" ]]; then
  echo "🧹 Clean-up"
  rm -Rf "${DMG_TEMP}"
fi
