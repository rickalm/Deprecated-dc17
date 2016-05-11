docker rm -f dind-test

[ -z "$1" ] && D=-d
docker run --privileged -it --net=host --name=dind-test $D \
  rickalm/centos-dind-systemd:7 $@

docker exec -it dind-test /bin/bash
