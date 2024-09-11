import json
import boto3
from pprint import pprint
import os

s3_client = boto3.client("s3")
# environment variables of lambda functions
s3_bucket = os.environ["S3_BUCKET"]
s3_prefix = ""
s3_file = "files/ng-test.txt"

s3_path = "upload/" + s3_file

def s3_write(s3_path,s3_bucket):
    f = open(s3_file,"r")
    string = f.read()
    #string = "dfghj"
    encoded_string = string.encode("utf-8")
    s3 = boto3.resource("s3")
    s3.Bucket(s3_bucket).put_object(Key=s3_path, Body=encoded_string)


def lambda_res(res_body, statusCode):
    return {
	'statusCode': statusCode,
	'headers': {
            "Access-Control-Allow-Origin": "*",
	    "Content-Type": "text/html; charset=utf-8"
	},
	'body': res_body
    }


def rootPage():
    f = open("html/index.html", "r")
    s3_write(s3_path,s3_bucket)
    return(lambda_res(f.read(), 200))


def Err404Page():
    f = open("html/404.html", "r")
    return(lambda_res(f.read(), 400))

def loginPage():
    #f = open("html/index.html", "r")
    f = open("html/login.html", "r")
    return(lambda_res(f.read(), 200))

def UploadPage():
    f = open("html/upload.html", "r")
    return(lambda_res(f.read(), 200))




def handler(event, context):
    RandomBool = True
    myString = "/"
    myPath = "MYPATH"
    Err404 = "Error 404"

    req_path = event["requestContext"]["http"]["path"]
    print("Event here: ")
  
    if req_path == "/":
       return rootPage()
    elif req_path == "/login":
       return loginPage()
    elif req_path == "/upload":
       return UploadPage()
    else:
       return Err404Page()
    
    return Err404







def blabla():
    return {'statusCode': 200,
            'headers': {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": 'GET, POST, PUT, DELETE, OPTIONS'
            },
            'body': json_data
        }    
