DEBIAN_SUITE=jessie
DEBIAN_MIRROR=http://gce_debian_mirror.storage.googleapis.com/
DOCKER_REPO=google/debian
ROOTFS_TAR=google-debian-${DEBIAN_SUITE}.tar.bz2

.PHONY: docker-image update-mkimage clean

all: docker-image

docker-image: ${ROOTFS_TAR}
	docker build -t ${DOCKER_REPO}:${DEBIAN_SUITE} .

${ROOTFS_TAR}: builder
	@# Ensure an old builder isn't sitting around
	docker rm --volumes builder || true
	@# We need to run the builder in privileged mode so it can run
	@# chroot as part of debootstrap
	docker run \
		--name builder \
		-it \
		--privileged \
		--volume /var/$(DEBIAN_SUITE) \
		gae-builder \
			-d /var/$(DEBIAN_SUITE) \
			--compression bz2 \
			debootstrap \
			--variant=minbase \
			$(DEBIAN_SUITE) \
			$(DEBIAN_MIRROR)
	docker cp builder:/var/$(DEBIAN_SUITE)/rootfs.tar.bz2 $@
	docker rm --volumes builder

clean:
	rm -f ${ROOTFS_TAR}
	docker rm --volumes builder || true
	docker rmi gae-builder || true

.PHONY: builder
builder:  ## Create a builder image for easy generation of base images
	cd builder && docker build \
		-t gae-builder \
		--build-arg DOCKER_VERSION=1.11.2 \
		--file builder.Dockerfile .
