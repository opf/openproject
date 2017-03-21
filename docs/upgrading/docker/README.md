# Upgrade your OpenProject installation (Docker)

Upgrading a Docker container is easy. First, pull the latest version of the image:

    docker pull openproject/community:5.0

Then stop and remove your existing container:

    docker stop openproject
    docker rm openproject

Finally, re-launch the container in the same way you launched it previously.
This time, it will use the new image:

    docker run -d ... openproject/community:5.0

