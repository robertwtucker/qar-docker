include ../make/Makefile

REGISTRY_HOST=registry.sptcloud.com
USERNAME=spt

pre-build:
	mkdir -p od
	cp -f ../../http-server/files/od/od-response.file od
	cp -f ../../http-server/files/od/odpdf-response.file od
	cp -f ../../qar-home/qar-home.tar .

post-build:
	rm -rf od
	rm -f qar-home.tar
