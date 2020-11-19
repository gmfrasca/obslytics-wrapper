FROM quay.io/avsrivas/golang:1.14
# set up obslytics
RUN go get -d -v github.com/thanos-community/obslytics/cmd/obslytics
WORKDIR /go/src/github.com/thanos-community/obslytics/cmd/obslytics
RUN go install .
RUN  export PATH=$PATH:$(dirname $(go list -f '{{.Target}}' .))
WORKDIR /root
# Set up wrapper script
COPY . .
RUN GO111MODULE=on go get github.com/mikefarah/yq/v3
CMD ["bash","./run.sh"]
