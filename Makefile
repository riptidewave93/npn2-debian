.DEFAULT_GOAL := build

setup:
	sudo modprobe loop; \
	sudo modprobe binfmt_misc; \
	docker run --rm --privileged multiarch/qemu-user-static:register --reset

build: setup
	@set -e;	\
	for file in `ls ./scripts/[0-99]*.sh`;	\
	do					\
		bash $${file};			\
	done					\

clean:
	sudo rm -rf $(CURDIR)/BuildEnv; \
	docker ps -a | awk '{ print $$1,$$2 }' | grep npn2-debian | awk '{print $$1 }' | xargs -I {} docker rm {};

distclean: clean
	docker rmi npn2-debian:builder -f; \
	docker rmi npn2-debian:debootstrap-arm64 -f; \
	rm -rf $(CURDIR)/downloads;

mountclean:
	sudo umount $(CURDIR)/BuildEnv/rootfs/boot; \
	sudo umount $(CURDIR)/BuildEnv/rootfs; \
	sudo losetup -D;