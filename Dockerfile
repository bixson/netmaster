FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    dnsutils \
    ttyd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY netmaster.sh /app/netmaster.sh
RUN chmod +x /app/netmaster.sh

EXPOSE 7681

CMD ["ttyd", "--port", "7681", "--writable", "bash", "/app/netmaster.sh"]
