from debian:jessie

MAINTAINER alljoynsville

ADD ./init.sh /init.sh
RUN /init.sh

ADD ./daemon-build.sh /daemon-build.sh
RUN /daemon-build.sh

ADD ./gwagent-build.sh /gwagent-build.sh
RUN /gwagent-build.sh

ADD ./connector.sh /connector.sh
RUN /connector.sh



ADD ./run.sh /run.sh
CMD ["/run.sh"]

