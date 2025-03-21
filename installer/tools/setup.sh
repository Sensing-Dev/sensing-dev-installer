#!/bin/bash
: '
.SYNOPSIS
Installs the Sensing SDK.

.DESCRIPTION
This script downloads and installs the Sensing SDK on Ubuntu. You can specify a particular version or the latest version will be installed by default.

.PARAMETER version/-v
Specifies the version of the Sensing SDK to be installed. Default is 'latest'.

.PARAMETER install-opencv
If set, the script will also install OpenCV. This is not done by default.

.PARAMETER install-path
The installation path for the Sensing SDK.Default is the /opt/sensing-dev directory

.PARAMETER develop-test
Requires this option for non-tagged GitHub Workflow.'

set -eo pipefail
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi



unset ion_kit_config
declare -A ion_kit_config=( # Declare an associative array with default values
    ["v24.05.04"]="v1.8.2"
    ["v24.05.05"]="v1.8.2"
    ["v24.05.06"]="v1.8.3"
    ["v24.05.07"]="v1.8.4"
    ["v24.05.08"]="v1.8.5"
    ["v24.05.09"]="v1.8.7"
    ["v24.05.10"]="v1.8.8"
    ["v24.05.11"]="v1.8.9"
    ["v24.05.12"]="v1.8.10"
)

unset gendc_separator_config
declare -A gendc_separator_config=( # Declare an associative array with default values
    ["v24.05.04"]="v0.2.6"
    ["v24.05.05"]="v0.2.7"
    ["v24.05.06"]="v0.2.8"
    ["v24.05.07"]="v0.2.8"
    ["v24.05.08"]="v0.2.8"
    ["v24.05.09"]="v0.2.8"
    ["v24.05.10"]="v0.2.8"
    ["v24.05.11"]="v0.2.8"
    ["v24.05.12"]="v0.2.8"
)

unset aravis_config
declare -A aravis_config=( # Declare an associative array with default values
    ["v24.05.04"]="0.8.30-internal"
    ["v24.05.05"]="0.8.30-internal"
    ["v24.05.06"]="0.8.30-internal"
    ["v24.05.07"]="0.8.30-internal"
    ["v24.05.08"]="0.8.30-internal"
    ["v24.05.09"]="0.8.30-internal"
    ["v24.05.10"]="0.8.30-internal"
    ["v24.05.11"]="v0.8.30-internal.1"
    ["v24.05.12"]="v0.8.30-internal.1"
)

unset aravis_url
declare -A aravis_url=( # Declare an associative array with default values
    ["0.8.30-internal"]="https://github.com/Sensing-Dev/aravis/releases/download/internal-0.8.30/aravis-internal-0.8.30-x86-64-linux.tar.gz"
    ["v0.8.30-internal.1"]="https://github.com/Sensing-Dev/aravis/releases/download/v0.8.30-internal.1/aravis-0.8.30-internal.1-x86-64-linux.tar.gz"
)

EARLIEST_STABLE_SDK="v24.05.04"

INSTALL_PATH=/opt/sensing-dev

while true; do
  case "$1" in
    --install-opencv )
      InstallOpenCV=true;
      shift ;;
    -v | --version )
      Version="$2";
      shift; shift ;;
    --install-path )
      INSTALL_PATH="$2";
      shift; shift ;;
    --develop-test )
      NOT_DL_VERSION_INFO=true;
      shift ;;
    -- )
      shift; break ;;
    * )
      break ;;
  esac
done

# if version is not specified, get the latest #########################################################
get_sensing-dev_latest_release() {

  curl --silent "https://api.github.com/repos/$1/releases/latest" | # Get latest release from GitHub api
    grep '"tag_name":' |                                            # Get tag line
    sed -E 's/.*"([^"]+)".*/\1/'                                    # Pluck JSON value
}

if [ -z "$Version" ]; then
  Repository="Sensing-Dev/sensing-dev-installer"
  Version=`get_sensing-dev_latest_release $Repository`
  if [[ "$Version" == "v24.01.04" ]]; then
    Version="$EARLIEST_STABLE_SDK"
  fi
fi

if [[ $Version =~ ^v[0-9]+\.[0-9]+\.[0-9]+-.*$ ]]; then
  Alt_Version=$(echo $Version | sed 's/-.*//');
else
  Alt_Version=$Version;
fi

echo "========"
echo This script will try to $Version and its same as $Alt_Version

if [[ -z "${ion_kit_config[$Alt_Version]+_}" ]]; then
  echo "Error: Version '$Alt_Version' is not found from following versions for Linux"
  for v in "${!ion_kit_config[@]}"; do
    echo $v
  done
  exit 1
fi


#######################################################################################################

ION_KIT_VERSION=${ion_kit_config["$Alt_Version"]}
GENDC_SEPARATOR_VERSION=${gendc_separator_config["$Alt_Version"]}
ARAVIS_VERSION=${aravis_config["$Alt_Version"]}
ARAVIS_URL=${aravis_url["$ARAVIS_VERSION"]}

mkdir -p $INSTALL_PATH

echo "**********"
echo "Install Dependencies"
echo "**********"
apt-get -y upgrade && apt-get update && apt-get install -y curl gzip git python3-pip glib2.0 libxml2-dev \
    libgirepository1.0-dev libnotify-dev \
    libunwind-dev \
    libgstreamer1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgtk-3-dev \
    gtk-doc-tools


echo
echo "**********"
echo "Install aravis=${ARAVIS_VERSION}"
echo "**********"

curl -L ${ARAVIS_URL}| tar zx -C $INSTALL_PATH --strip-components 1
mkdir -p /etc/udev/rules.d
cat > /etc/udev/rules.d/80-aravis.rules << EOS
SUBSYSTEM=="usb", ATTRS{idVendor}=="054c", MODE:="0666", TAG+="uaccess", TAG+="udev-acl"
EOS
echo "INFO: Aravis installed"

# Install OpenCV if the flag is set to true
if [ "$InstallOpenCV" = true ]; then
    echo
    echo "**********"
    echo "Install OpenCV"
    echo "**********"
    TMPDIR=$(mktemp -d)
    curl -L https://ion-kit.s3.us-west-2.amazonaws.com/dependencies/OpenCV-4.5.2-x86_64-gcc75.sh -o ${TMPDIR}/OpenCV.sh
    sh ${TMPDIR}/OpenCV.sh --skip-license --prefix=$INSTALL_PATH
    echo "INFO: OpenCV installed"
fi


echo
echo "**********"
echo "Install ion-kit=${ION_KIT_VERSION/v/''}"
echo "**********"
if [ ${ION_KIT_VERSION} = v0.3.6 ]; then
   curl -L https://github.com/fixstars/ion-kit/releases/download/${ION_KIT_VERSION}/ion-kit-${ION_KIT_VERSION/v/''}-Linux.tar.gz | tar xz -C  $INSTALL_PATH --strip-components 1
else
  curl -L https://github.com/fixstars/ion-kit/releases/download/${ION_KIT_VERSION}/ion-kit-${ION_KIT_VERSION/v/''}-x86-64-linux.tar.gz | tar xz -C  $INSTALL_PATH --strip-components 1
fi

echo
echo "**********"
echo "Install GenDCSeparator=${GENDC_SEPARATOR_VERSION/v/''}"
echo "**********"
curl -L https://github.com/Sensing-Dev/GenDC/releases/download/${GENDC_SEPARATOR_VERSION}/gendc_separator_${GENDC_SEPARATOR_VERSION}_win64.zip -o gendc_separator.zip && unzip -o gendc_separator.zip -d $INSTALL_PATH/include && rm gendc_separator.zip

if [ "$NOT_DL_VERSION_INFO" = true ]; then
      echo
      echo "**********"
      echo "develop-test mode doesn't DL version_info.json"
      echo "**********"
else
  if [[ "$Version" == "v24.05.04" ]]; then
      echo
      echo "**********"
      echo "This version doesn't support version_info.json"
      echo "**********"
  else
      # DL version_info.json
      echo
      echo "**********"
      echo "Download SDK version info... See $INSTALL_PATH/version_info.json for the detail."
      echo "**********"
      curl -L https://github.com/Sensing-Dev/sensing-dev-installer/releases/download/${Version}/version_info.json -o $INSTALL_PATH/version_info.json
  fi
fi

echo
echo "Successfully Finished."
