#!/bin/bash

set -e -o pipefail

PACKAGE_LOCATION="${1}"
BINTRAY_REPO="${2}"
BINTRAY_LICENSE="${3}"
BINTRAY_USERNAME="${4}"
BINTRAY_API_KEY="${5}"
BINTRAY_VCS_URL="https://github.com/${GITHUB_REPOSITORY}"

git_tmp_dir=$(mktemp -d /tmp/distro-info-data-XXXXX)

function jfrog_upload {
    linux_version=$1
    pkg_filename=$2
    IFS=_ read -r pkg_name pkg_version pkg_arch <<< "$(basename -s ".deb" "${pkg_filename}")"

    echo "==== Uploading ${pkg_filename} to ${linux_version}/main/${pkg_arch} ===="

    jfrog bt package-create --licenses "${BINTRAY_LICENSE}" --vcs-url "${BINTRAY_VCS_URL}" "${BINTRAY_REPO}/${pkg_name}" || true
    jfrog bt upload --publish=true --deb "${linux_version}/main/${pkg_arch}" "${pkg_filename}" "${BINTRAY_REPO}/${pkg_name}/${pkg_version}" "pool/${linux_version}/main/${pkg_name}/"
}

curl --silent -fL -XGET \
    "https://api.bintray.com/content/jfrog/jfrog-cli-go/\$latest/jfrog-cli-linux-amd64/jfrog?bt_package=jfrog-cli-linux-amd64" \
    > /usr/local/bin/jfrog
chmod +x /usr/local/bin/jfrog
mkdir -p ~/.jfrog/
cat << EOF > ~/.jfrog/jfrog-cli.conf
{
  "artifactory": null,
  "bintray": {
    "user": "${BINTRAY_USERNAME}",
    "key": "${BINTRAY_API_KEY}"
  },
  "Version": "1"
}
EOF

# Fetch current debian/ubuntu versions
git clone --depth 1 https://salsa.debian.org/debian/distro-info-data "${git_tmp_dir}"

# Loop over all directories
while IFS= read -r -d '' path
do
    if [ "$(basename "${path}")" == "all" ]; then
        # Upload these debs to all current debian/ubuntu versions
        while IFS= read -r -d '' deb; do
            pkg_filename=$(basename "${deb}")

            for release in $(awk -F ',' -v today="$(date --utc "+%F")" \
                'BEGIN {OFS=","} NR>1 { if (($6 == "" || $6 >= today) && ($5 != "" && $5 <= today)) print $3 }' \
                "${git_tmp_dir}/ubuntu.csv"); do
                jfrog_upload "${release}" "${deb}"
            done

            for release in $(awk -F ',' -v today="$(date --utc "+%F")" \
                'BEGIN {OFS=","} NR>1 { if (($6 == "" || $6 >= today) && ($4 != "" && $4 <= today)) print $3 }' \
                "${git_tmp_dir}/debian.csv" | grep -v -E "(sid|experimental)"); do
                jfrog_upload "${release}" "${deb}"
            done
        done <   <(find "${path}" -maxdepth 1 -type f -print0)
    else
        # Upload just this specific version of debian or ubuntu
        IFS=_ read -r distro release <<< "$(basename "${path}")"

        while IFS= read -r -d '' deb
        do
            jfrog_upload "${release}" "${deb}"
        done <   <(find "${path}" -maxdepth 1 -type f -print0)
    fi
done <   <(find "${PACKAGE_LOCATION}" -mindepth 1 -maxdepth 1 -type d -print0)

rm -rf "${git_tmp_dir}"
