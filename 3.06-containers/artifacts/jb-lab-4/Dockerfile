# jb-lab-4: a tiny web image. The base image comes from ECR Public (no Docker Hub limits).
FROM public.ecr.aws/nginx/nginx:alpine

ARG VERSION=v1

# Serve the page at "/" (health check) and at "/web/" (the ALB rule /web*)
COPY index.html /usr/share/nginx/html/index.html
RUN mkdir -p /usr/share/nginx/html/web \
 && sed -i "s/__VERSION__/${VERSION}/" /usr/share/nginx/html/index.html \
 && cp /usr/share/nginx/html/index.html /usr/share/nginx/html/web/index.html
