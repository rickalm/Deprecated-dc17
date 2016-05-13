#! /bin/bash

docker build -f Dockerfile.centos7-base:7 -t rickalm/centos7-base:7 .
docker build -f Dockerfile.centos7-dind-systemd:7 -t rickalm/centos7-dind-systemd:7 .
docker build -f Dockerfile.centos7-systemd-dind:7 -t rickalm/centos7-systemd-dind:7 .
