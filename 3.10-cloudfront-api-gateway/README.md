# 3.10 CloudFront & API Gateway

> **Coming soon.** This chapter is planned. The topics below are its outline.

The two front doors of an application on AWS: **Amazon CloudFront** delivers content from edge locations close to your users, and **Amazon API Gateway** exposes APIs in front of Lambda and other back ends.

## Topics

### Amazon CloudFront

- Edge Locations and Regional Edge Caches (introduced in [2.01](../2.01-global-infrastructure/README.md))
- Distributions and origins: S3, ALB, custom origins
- Origin Access Control (OAC): keep the S3 bucket private
- Cache behaviors, TTLs and invalidations
- HTTPS with AWS Certificate Manager (the certificate lives in `us-east-1`) and a custom domain with Route 53
- Price classes and geo restriction
- AWS Global Accelerator vs. CloudFront

### Amazon API Gateway

- REST vs. HTTP vs. WebSocket APIs
- Lambda proxy integration
- Stages and deployments
- Throttling and usage plans
- CORS
- Custom domains
- Endpoint types: edge-optimized (through CloudFront), regional, private

## Planned Labs

- CloudFront with OAC in front of the S3 static website from [3.03 Amazon S3](../3.03-s3/README.md)
- An HTTP API in front of a Lambda function from [3.05 Serverless: AWS Lambda](../3.05-lambda/README.md)

---

[⬅ Previous: 3.09 Amazon Route 53](../3.09-route53/README.md) | [🏠 Home](../README.md) | [Next: 3.11 Project: Simple Website on Lambda ➡](../simple-website-lambda/)

---

## Contact

For questions or feedback, feel free to reach out:

- **Email**: eyal@levys.co.il
- **GitHub**: [https://github.com/elevy99927](https://github.com/elevy99927)
