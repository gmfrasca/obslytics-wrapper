# Obslytics-wrapper
## This is a container image for the [Obslytics](https://github.com/thanos-community/obslytics) Project

### Building container image
* Create Configuration files for Metric Source [(Input)](https://github.com/4n4nd/obslytics-wrapper/blob/a4ef9dcc7c463b0c434308a74c5e07adb8a7b8fd/example-input-config.yaml) 
    and Metric Storage [(Output)](https://github.com/4n4nd/obslytics-wrapper/blob/a4ef9dcc7c463b0c434308a74c5e07adb8a7b8fd/example-storage-config.yaml).
* Run the following command in the root of the repository: <br>
    `docker build . -t obslytics-wrapper`
  
### Start a new container
* Set up all the [required parameters](https://github.com/4n4nd/obslytics-wrapper/blob/main/run.sh#L1-L12) 
    in a file [(Example)](https://github.com/4n4nd/obslytics-wrapper/blob/main/.env-example).
* Then run the following command: <br>
    `docker run --network=host -it --env-file=.env-example obslytics-wrapper:latest`