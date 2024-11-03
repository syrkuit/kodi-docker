Dockerized [Kodi](https://kodi.tv/download) based on [Alpine image](https://hub.docker.com/_/alpine).

This is **not** a headless setup, Kodi runs in full screen mode using GBM Windowing with HDR support (assuming your monitor is capable) and video hardware acceleration.

# Installation

```
sudo docker build --tag kodi `awk -F : '/^(audio|render|video):/ {printf "%s%s%s%s", " --build-arg KODI_", toupper($1), "=", $3}' /etc/group` .
```

By default, this uses the Alpine `latest` image, you can override the image with `--build-arg ALPINE_TAG=<tag>`.

By default, kodi runs as user kodi with uid 1000, you can override the defaults with

* uid: `--build-arg KODI_UID=1042`
* gid: `--build-arg KODI_UID=1042`

# Usage

```
sudo docker run --mount type=bind,src=/path/to/your/media,dst=/media \
  -p 8080:8080 -p 9090:9090 -p 9777:9777/udp \
  --device /dev/dri --device /dev/snd \
  kodi
```

## Notes

* If you want the kodi state to be accessible outside of docker (and to be persisted when you upgrade), create a directory with the correct permissions and add the following argument: `--mount type=bind,src=/path/to/created/directory,dst=/var/lib/kodi/.kodi`
* Don't forget to add your media, for example `--mount type=bind,src=/path/to/media,dst=/media`. Note that the provided image does not support access over NFS or Samba *within the container*.
* Kodi needs to be controlled via remote, the web server is enabled by default without requiring any password. **Once it is working, set a password** in `Settings → Services → Control → Web server`.
* To check what HDR types are detected, see `Settings → System information → Video`.
* I cannot test NVIDIA support and some packages are probably missing, send a PR to fix.

# Troubleshooting

If Kodi is "Unable to create GUI", follow these steps:

### Get things working with extended privileges

The following **should** work:
* run with `--privileged` to allow access to all devices
* run as `root` to avoid any issues with permissions


```
sudo docker run -p 8080:8080 -p 9090:9090 -p 9777:9777/udp --user root --privileged --rm -ti kodi-x11
```

If the above does not work, then something's off with the image itself and you need to dive in and tweak the `Dockerfile`.

### Drop extended privileges

Once you have a working image, it's time to look at dropping unnecessary privileges.

First, while the container is running with `--privileged`, note the devices in use by running the following command on the host: ``sudo lsof -p `pgrep kodi-xbm` | grep /dev/``

Second, replace the `--privileged` flag with `--cap-add ALL`, and make the necessary devices available within the container with `--device`. Keep running the docker command until you find the right combination.

Once things look good, remove the `--cap-add ALL` flag and see if things still work. If yes, great, you're done, otherwise work through the list of [capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) until you find the necessary one(s).

### Switch to a regular user

Once you have a working image with limited privileges, try again without `--user root`.
