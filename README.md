Dockerized [Kodi](https://kodi.tv/download) based on [Debian image](https://hub.docker.com/_/debian).

This is **not** a headless setup, it expects X11 to work inside the docker container which can be tricky, see below.

# Installation

```
sudo docker build --tag kodi-x11 .
```

By default, it will use Debian `sid-slim` image, you can override the image with `--build-arg DEBIAN_TAG=<tag>`.

By default, kodi will run as user kodi with uid 1000, you can override the defaults with

* uid: `--build-arg KODI_UID=1042`
* gid: `--build-arg KODI_UID=1042`

# Usage

```
sudo docker run --mount type=bind,src=/data/media,dst=/media \
  -v /etc/localtime:/etc/localtime:ro -v /etc/timezone:/etc/timezone:ro \
  -p 8080:8080 -p 9090:9090 -p 9777:9777/udp \
  --device /dev/tty0 --device /dev/tty2 --device /dev/dri --device /dev/snd \
  --cap-add SYS_ADMIN \
  --rm -ti kodi-x11
```

## Notes

* If you want the kodi state to be accessible outside of docker, create a directory with the correct permissions and add the following argument: `--mount type=bind,src=/path/to/created/directory,dst=/kodi/.kodi`
* Don't forget to add your media, for example `--mount type=bind,src=/path/to/media,dst=/media`. Note that the provided image does not support access over NFS or Samba *within the container*.
* This image doesn't provide for a working keyboard/mouse, Kodi needs to be controlled via remote.

# Troubleshooting

If X11 fails to start with the options above, start from scratch using the `latest` Debian image (instead of `sid-slim`), and then follow these steps:

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

First, while the container is running with `--privileged`, note the devices in use by running the following command on the host: ``sudo lsof -p `pgrep Xorg` | grep /dev/``

Second, replace the `--privileged` flag with `--cap-add ALL`, and make the necessary devices available within the container with `--device`. Keep running the docker command until you find the right combination. The following error messages are pretty common:

* `parse_vt_settings: Cannot open /dev/tty0 (No such file or directory)`: need to add `/dev/tty0`
* `xf86OpenConsole: Cannot open virtual console 2 (No such file or directory)`: need to add `/dev/tty2`
* `no screens found`: need to add `/dev/dri`

Once things look good, remove the `--cap-add ALL` flag and see if things still work. If yes, great, you're done, otherwise work through the list of [capabilities](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) until you find the necessary one(s).

### Switch to a regular user

Once you have a working image with limited privileges, try again without `--user root`.
