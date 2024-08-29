---
sidebar_navigation:
  title: Development setup via docker on MacOS
  short_title: Setup via Docker on MacOS
description: OpenProject development setup via docker on MacOS
keywords: development setup docker macos
---

# OpenProject development setup via docker (MacOS)

This guide covers observed nuances with the docker runtime on MacOS. Please ensure you've gone through the general [OpenProject development setup via docker](../docker) guide before proceeding.

## Docker on MacOS File System Performance

Docker on Mac is [known to have file system performance issues](https://github.com/docker/roadmap/issues/7) due to the fact that Docker runs in a virtual machine on MacOS.
Container operations are slower than they would be in a native Linux environment.

As Docker runs in a virtual machine, a shared filesystem is needed and applications such as OpenProject with large number of files may experience performance drawbacks.

[Switching to VirtioFS filesystem implementation](https://www.docker.com/blog/speed-boost-achievement-unlocked-on-docker-desktop-4-6-for-mac/) can help improve the file system performance. Although Virtio FS is available on [Docker Desktop](https://docs.docker.com/desktop/install/mac-install/), [Orbstack + VirtioFS](https://orbstack.dev/) provides a more consistent experience in performance and resource usage; significantly less than docker desktop + VirtioFS. [According to OrbStack](https://docs.orbstack.dev/architecture#docker), the overall architecture is similar to Docker Desktop but more specialized and lightweight.

The following is a benchmark performed on a _MacBook Pro, 2019 16 GB 2667 MHz DDR4 2.3 GHz 8-Core Intel Core i9_

```shell
time docker compose exec backend-test bundle exec rspec spec/models/work_package_spec.rb
```

| Runtime    | Run1 | Run2|
| -------- | ------- |-------|
| Docker Desktop + gRPC FUSE (default)  | 1m32s - Finished in 7.09 seconds (files took 1 minute 23.63 seconds to load)  |  1m31s - Finished in 7.34 seconds (files took 1 minute 22.52 seconds to load)|
| Docker Desktop + VirtioFS  |  170.66 real - Finished in 12.04 seconds (files took 2 minutes 33.7 seconds to load)  | 97.97 real - Finished in 15.22 seconds (files took 1 minute 16.85 seconds to load) |
| Colima Qemu  | 469.08 real - Finished in 19.25 seconds (files took 7 minutes 22 seconds to load)     |  270.75 real - Finished in 17.05 seconds (files took 4 minutes 5.9 seconds to load) |
| OrbStack + VirtioFS  | 79.56 real - Finished in 7.74 seconds (files took 1 minute 9.49 seconds to load)    | 41.04 real - Finished in 7.72 seconds (files took 31.7 seconds to load) |

### Orbstack Installation

_Ref Quick Start Guide [here](https://docs.orbstack.dev/quick-start)_

```shell
brew install orbstack
```

**Note:** You can use Docker contexts to run OrbStack and Docker Desktop side-by-side. Switching contexts affects all Docker commands you run from that point on. [Ref: Side-by-side](https://docs.orbstack.dev/install#reverting)

```shell
# Switch to OrbStack
docker context use orbstack
# Switch to Docker Desktop
docker context use desktop-linux
```

To view the list of docker contexts run:

```shell
docker context ls
```
