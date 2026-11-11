module "module-example" {
  source = "../modules/jb-module"         
  size = "t3.large"                    
  number-instances = 5      
  region = "eu-west-1"
}


terraform {
  backend "s3" {
    bucket = "jblabs-elevy99927-1111" 
    key = "jb-terraform/lab-6.tfstate"
    region = "us-east-1"
  }
}