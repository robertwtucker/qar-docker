include ../make/Makefile

REGISTRY_HOST=registry.sptcloud.com
USERNAME=qar

IMAGE_BASE=ubi-8.7-1112
DOCKER_BUILD_ARGS=--build-arg INSTALL_FILES_URL=${INSTALL_FILES_URL}

pre-build:
	mkdir -p od
	cp -f ../../http-server/files/od/od-response.file od
	cp -f ../../http-server/files/od/odfts-response.file od
	cp -f ../../qar-home/qar-home.tar .

post-build:
	docker tag "${IMAGE}:${VERSION}" "${IMAGE}:${VERSION}-${IMAGE_BASE}"
	rm -rf od
	rm -f qar-home.tar

post-push:
	docker push "${IMAGE}:${VERSION}-${IMAGE_BASE}"
