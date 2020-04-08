# action-bintray-upload-debian-packages

Github action for uploading debian packages to bintray.

## Inputs

### `path`

**Required** Path to a directory full of packages with the following structure:

```
all/*.deb
distro_version1/*.deb
distro_version2/*.deb
distro_versionN/*.deb
```

Packages in the `all/` directory will be uploaded to all currently supported
Debian and Ubuntu versions.

Packages in the `distro_version/` directory (e.g. debian_buster) will just be
uploaded to that particular version of Debian or Ubuntu.

### `repo`

**Required** The Bintray repository to upload to

### `license`

**Required** Open-source license the package is licensed as

### `username`

**Required** The Bintray username to use for authentication

### `api_key`

**Required** The Bintray API key to use for authentication

## Example usage

```
uses: wanduow/action-bintray-upload-debian-packages@v1
with:
  path: packages/
  repo: bearwall/bearwall2
  license: GPL-2.0
  username: bearwall-maintainer
  api_key: ${{ secrets.BINTRAY_API_KEY }}
```
