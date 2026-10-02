#!/bin/sh

finish() {
  set +e
  echo "Removing containers..."
  [ "$deunhealthID" != "" ] && docker rm -f "$deunhealthID"
  [ "$nohealthID" != "" ] && docker rm -f "$nohealthID"
  [ "$healthyID" != "" ] && docker rm -f "$healthyID"
  [ "$unhealthyID" != "" ] && docker rm -f "$unhealthyID"
  [ "$nohealthMarkedID" != "" ] && docker rm -f "$nohealthMarkedID"
  [ "$healthyMarkedID" != "" ] && docker rm -f "$healthyMarkedID"
  [ "$unhealthyMarkedID" != "" ] && docker rm -f "$unhealthyMarkedID"
  echo "done"
}
trap finish EXIT

set -e

docker --version
[ $? = 0 ] || ( echo "Docker not installed!"; exit 1 )

# docker build -t qmcgaw/deunhealth .

healthFlags="--health-start-period=0s --health-interval=40ms --health-retries=1"
restartOnUnhealthyLabel="--label deunhealth.restart.on.unhealthy=true"

echo "launching test containers"

nohealthID="$(docker run -d --init alpine:3.22 sleep 30)"
healthyID="$(docker run -d --init --health-cmd='exit 0' $healthFlags alpine:3.22 sleep 30)"
unhealthyID="$(docker run -d --init --health-cmd='exit 1' $healthFlags alpine:3.22 sleep 30)"
nohealthMarkedID="$(docker run -d --init $restartOnUnhealthyLabel alpine:3.22 sleep 30)"
healthyMarkedID="$(docker run -d --init $restartOnUnhealthyLabel --health-cmd='exit 0' $healthFlags alpine:3.22 sleep 30)"
unhealthyMarkedID="$(docker run -d --init $restartOnUnhealthyLabel --health-cmd='exit 1' $healthFlags alpine:3.22 sleep 30)"

nohealthName="$(docker inspect -f '{{ .Name }}' $nohealthID | sed -r 's/^\///')"
healthyName="$(docker inspect -f '{{ .Name }}' $healthyID | sed -r 's/^\///')"
unhealthyName="$(docker inspect -f '{{ .Name }}' $unhealthyID | sed -r 's/^\///')"
nohealthMarkedName="$(docker inspect -f '{{ .Name }}' $nohealthMarkedID | sed -r 's/^\///')"
healthyMarkedName="$(docker inspect -f '{{ .Name }}' $healthyMarkedID | sed -r 's/^\///')"
unhealthyMarkedName="$(docker inspect -f '{{ .Name }}' $unhealthyMarkedID | sed -r 's/^\///')"

echo "launching deunhealth"

deunhealthID="$(docker run -d -v /var/run/docker.sock:/var/run/docker.sock qmcgaw/deunhealth)"

echo "waiting 1 second"

sleep 1

logs="$(docker logs $deunhealthID)"

[ "$(echo $logs | grep -o $nohealthName | wc -l)" = "0" ] || ( echo "Container $nohealthName appears in deunhealth logs"; echo "$logs"; exit 1 )
[ "$(echo $logs | grep -o $healthyName | wc -l)" = "0" ] || ( echo "Container $healthyName appears in deunhealth logs"; echo "$logs"; exit 1 )
[ "$(echo $logs | grep -o $unhealthyName | wc -l)" = "0" ] || ( echo "Container $unhealthyName appears in deunhealth logs"; echo "$logs"; exit 1 )
[ "$(echo $logs | grep -o $nohealthMarkedName | wc -l)" != "0" ] || ( echo "Container $nohealthMarkedName does not appear in deunhealth logs"; echo "$logs"; exit 1 )
[ "$(echo $logs | grep -o $healthyMarkedName | wc -l)" != "0" ] || ( echo "Container $healthyMarkedName does not appear in deunhealth logs"; echo "$logs"; exit 1 )
[ "$(echo $logs | grep -o $unhealthyMarkedName | wc -l)" != "0" ] || ( echo "Container $unhealthyMarkedName does not appear in deunhealth logs"; echo "$logs"; exit 1 )
