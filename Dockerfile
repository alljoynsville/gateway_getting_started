from debian:jessie

MAINTAINER alljoynsville

ADD ./init.sh /init.sh

RUN /init.sh

ADD ./run.sh /run.sh

CMD ["/run.sh"]

