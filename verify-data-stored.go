package main

import (
	"os"
	"log"
	"io/ioutil"
	"path/filepath"
	"flag"
	"gopkg.in/yaml.v2"

	"github.com/aws/aws-sdk-go/aws"
        "github.com/aws/aws-sdk-go/aws/session"
        "github.com/aws/aws-sdk-go/aws/credentials"
        "github.com/aws/aws-sdk-go/service/s3"
)

// Storage Config YAML used in Obslytics
type StorageConfig struct {
	Storage struct {
		Config struct {
			Bucket string
			Access_Key string
			Secret_Key string
			Endpoint  string
		}
	}
}

func main() {
	// Parse Input Parameters
	filePtr := flag.String("output-config-file", "storage-config.local.yaml", "Storage Configuration YAML")
	prefix := flag.String("prefix", "", "Prefix/Key to check s3 for parquet file")
	flag.Parse()

	// Load Config from YAML
	configFile, _ := filepath.Abs(*filePtr)
	configYaml, err := ioutil.ReadFile(configFile)
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	var storageconfig StorageConfig
        err = yaml.Unmarshal(configYaml, &storageconfig)
        if err != nil {
                log.Fatalf("error: %v", err)
        }

	// Create Credentials
        creds := credentials.NewStaticCredentials(
	    storageconfig.Storage.Config.Access_Key,
	    storageconfig.Storage.Config.Secret_Key,
	    "",
        )

        // Create a single AWS session
        s, err := session.NewSession(&aws.Config{
	    Region: aws.String("us-east-1"),
            Endpoint: aws.String(storageconfig.Storage.Config.Endpoint),
            Credentials: creds,
        })
        if err != nil {
            log.Fatal(err)
        }
        svc := s3.New(session.Must(s, err))

	// Check S3 for the provided file prefix
	res, err := svc.ListObjects(&s3.ListObjectsInput {
		Bucket: aws.String(storageconfig.Storage.Config.Bucket),
		Prefix: aws.String(*prefix),
	})
	if err != nil {
		log.Fatal(err)
	}

	// Verify there is exactly 1 file at the provided key
	if len(res.Contents) != 1 {
		log.Fatalf("No object found at %v", *prefix)
		os.Exit(1)
	} else {
		log.Printf("Verified - dataframe found: %v", *prefix)
	}
}
