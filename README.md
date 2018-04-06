# Instruction

## Install docker on raspberry PI

```bash
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker <user>
```

## Connect to docker daemon

If you plan to clone this repository directly on raspberry, omit this step. However, it is
much more comfortable to work with files on some host machine. Therefore, you need to connect your docker client
on host machine to docker daemon on raspberry. I found [rdocker](https://github.com/dvddarias/rdocker) useful for that.

## Clone repository 

```bash
git clone --recurse-submodules https://github.com/CT-18/networks-docker
```

or

```bash
git clone --recursive https://github.com/CT-18/networks-docker
```
for old git versions (before 2.13)

## Build image

```bash
docker build -t <name> .
```

Here, "name" is an image name which we will use later.

## Run image

```bash
docker run --privileged -d -p 80:80 --name <name> <image_name>
```

* `--privileged` allows container access camera device. (you can use --device=/dev/<your_camera_name> instead)

* `-d` means detached mode - this command will return to your shell once container is started. To view container output, use `docker logs <name>`

* `-p 80:80` exposes http(hls) port to the world outside container

* <image_name> is the *image* name from pervious step. It determines which image to run.

* \<name> is the *container* name. Use it to manipulate particular container instance: pause, stop, view logs, etc...

## Stream

Located at ```http://<raspberry_addr>/live.m3u8 ```