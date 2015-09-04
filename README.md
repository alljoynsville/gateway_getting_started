# gateway_getting_started

tutorial + workspace for running the alljoyn gateway
code taken from: https://wiki.allseenalliance.org/gateway/getting_started

this code result is an automatic docker: https://hub.docker.com/r/alljoynsville/gateway_getting_started/

#run:
docker run -p 9955-9956:9955-9956/tcp -p 9955-9956:9955-9956/udp -p 5353:5353/udp -it --rm --net=host alljoynsville/gateway_getting_started


