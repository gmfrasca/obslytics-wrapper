FROM quay.io/internaldatahub/golang:1.14
USER 1001
ENV GOCACHE=/tmp
# set up obslytics
RUN go get -d -v github.com/gmfrasca/obslytics/cmd/obslytics
WORKDIR /go/src/github.com/gmfrasca/obslytics/cmd/obslytics
RUN go install .
RUN  export PATH=$PATH:$(dirname $(go list -f '{{.Target}}' .))
RUN GO111MODULE=on go get github.com/mikefarah/yq/v3
WORKDIR /home
# Set up wrapper script
COPY . .
CMD ["bash","./run.sh"]