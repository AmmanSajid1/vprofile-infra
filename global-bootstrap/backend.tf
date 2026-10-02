terraform {
    backend "s3" {
        bucket = "vprofile-tfstate-464209272334"
        key = "bootstrap/terraform.tfstate"
        region = "us-east-1"
        encrypt = true
        use_lockfile = true
    }
}