
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
    return(lambda_res(f.read(), 200))

def Err404Page():
    f = open("html/404.html", "r")
    return(lambda_res(f.read(), 400))

def loginPage():
    #f = open("html/index.html", "r")
    f = open("html/login.html", "r")
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
