# Advanced DynamoDB Lab: A Serverless File Catalog

[⬅ Back to 3.13 Databases](../README.md)

Your operations team receives files in S3 and wants a web page that lists every file received. In this lab you build that catalog: every upload under `incoming/` is recorded in a **DynamoDB** table by one Lambda function, and a second Lambda function serves the list as an HTML page at a public URL. You build it by hand in the AWS Console, then turn the running environment into Terraform code with **Terraformer**.

![The file catalog: you upload a file to the S3 bucket (in the Console or with aws s3 cp). Objects created under incoming/ trigger the writer Lambda function asynchronously; ignored/ does not. The writer calls PutItem on the DynamoDB table (partition key bucket_name, sort key object_key, one row per file). A browser calls the reader Lambda function through its public Function URL (auth NONE); the reader calls Scan on the table and returns an HTML table.](part-1-intro/images/file-catalog.jpg)

<sub>Diagram source: [part-1-intro/images/file-catalog.drawio](part-1-intro/images/file-catalog.drawio) (open it in [draw.io](https://app.diagrams.net) to edit)</sub>

## Chapters

Each chapter has its own page and video.

| # | Chapter | What you do |
|---|---|---|
| 1 | [Introduction](part-1-intro/README.md) | The task, the architecture, the acceptance test. Try the lab on your own first |
| 2 | [The DynamoDB table](part-2-dynamodb-table/README.md) | What DynamoDB is, and the catalog table with its partition key and sort key |
| 3 | [S3 → writer Lambda → DynamoDB](part-3-s3-writer-lambda/README.md) | The bucket, the writer's role, the writer function and its S3 trigger. Upload from the browser and with `aws s3 cp` |
| 4 | [The reader Lambda and its Function URL](part-4-reader-function-url/README.md) | The reader's role, the reader function with a public Function URL, and the HTML report |
| 5 | [From the Console to Terraform with Terraformer](part-5-terraformer/README.md) | Import the running environment into Terraform code, fix what Terraformer gets wrong, compare it with the full solution, clean up |

## What's in this folder

| Path | What it is |
|---|---|
| [`code/writer/lambda_function.py`](code/writer/lambda_function.py) | The writer handler (Part 3) |
| [`code/reader/lambda_function.py`](code/reader/lambda_function.py) | The reader handler (Part 4) |
| [`terraform/`](terraform/) | The complete solution as Terraform: the same 16 resources as Parts 2–4, in one `terraform apply` |

> 💰 **Cost:** a few cents at most. DynamoDB on-demand, Lambda, S3 and CloudWatch Logs for a handful of test files stay inside the AWS Free Tier. Delete everything at the end ([Part 5, clean up](part-5-terraformer/README.md#clean-up)).

> Tested in `us-east-1` on 23–24 November 2026 in a private AWS account: Python 3.14, Terraform 1.17, AWS provider 6.74, Terraformer 0.8.30. The account number in the screenshots is masked.

---
## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
