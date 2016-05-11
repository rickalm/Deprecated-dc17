#! /bin/sh
until /opt/mesosphere/bin/exhibitor_wait.py; do
  sleep 10
done
