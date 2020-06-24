---
sidebar_navigation:
  title: Other
  priority: 0
---

# Instruction for specific platforms

OpenProject only comes either as [docker container](../docker/) or a [package](../packaged/).
The respective sections explain everything you need to know.

To make things easier here we give further instructions on how to get up and running with OpenProject
on different platforms which use either the docker container or the package.

## Kubernetes

Kubernetes is a container orchestration tool. As such it can use the
OpenProject docker container in the same manner as shown in the [docker section](../docker/#recommended-usage).

You can translate OpenProject's [`docker-compose.yml`](https://github.com/opf/openproject/blob/stable/10/docker-compose.yml)
for use in Kubernetes using [Kompose](https://github.com/kubernetes/kompose)
as described in the Kubernetes [documentation](https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/).

## Synology

Synology offers NAS devices that come with a UI for starting docker containers on them.
This means OpenProject has to be used exactly as described in the [docker](../docker/#recommended-usage) section.

### Launching the container

Launching OpenProject works like launching any other container in [Synology](https://www.synology.com/en-global/knowledgebase/DSM/help/Docker/docker_container).

First you have to go to the **Registry** section and download the OpenProject image.
It's best to choose the specific tag of the latest stable version (`openproject/community:10` at the time of writing).
You can use `:latest` too but it might lead to surprises when a major version upgrade happens.

Below are some settings you have to pay attention to when launching the container.

**Volumes**

Most importantly you **have to configure mounted volumes** for `pgdata` and `assets` as described in that section.
When launching the container you can configure this under the advanced settings in the volumes tab.
Otherwise you will lose your data when the container is deleted during an update.

**Ports**

You should also configure a specific port in the network tab so that your container will always run
on the same port. Otherwise it might happen that the port changes when the container restarts.

**Restart policy**

You should also check the "always restart" option when launching the container.

### Updates

For updates to be safe make sure that you have mounted the `pgdata` and `assets` folders as volumes.
Ideally you should also always backup these folders before any updates.

Updating the container then works like this:

    1. Go to the **Registry**
    2. Search for OpenProject, click download and choose the tag you want to update (e.g. 10 or latest).
    3. Stop the container once the new image has been downloaded.
    4. Click on clear and restart the container.

This will restart the container with the updated image.
Your OpenProject data will remain intact as long as you mounted the volumes as described above.

### FAQ

#### I had already started OpenProject without mounted volumes. How do I save my data during an update?

You will need to open a terminal on your Synology disk station.
Then you can extract your data from the existing container and mount it in a new one with the correct configuration.

    1. Stop the container to avoid changes to the data.
    2. Copy the data to a new directory on the host, e.g. `/volume1/openproject`.
    3. Launch the new container mounting the folders in that directory as described above.
    4. Delete the old container once you confirmed the new one is working correctly.

You can copy the data from the container using `docker cp` like this:

```
docker cp openproject-community1:/var/openproject/assets /volume1/openproject/assets
docker cp openproject-community1:/var/openproject/pgdata /volume1/openproject/pgdata
```

Make sure the folders have the correct owner so the new container can read and write them.

```
sudo chown -R 102 /volume1/openproject/*
```

After this it's simply a matter of launching the new container mounted with the copied `pgdata` and `assets` folders
as described earlier. Once that is done you can safely update the container.
