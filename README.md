# gateway_getting_started

tutorial + workspace for running the alljoyn gateway

tutorial source:   https://wiki.allseenalliance.org/gateway/getting_started
dockerfile source: https://github.com/alljoynsville/gateway_getting_started

automated result:  https://hub.docker.com/r/alljoynsville/gateway_getting_started/

#run:
docker run -p 9955-9956:9955-9956/tcp -p 9955-9956:9955-9956/udp -p 5353:5353/udp -it --rm --net=host alljoynsville/gateway_getting_started


