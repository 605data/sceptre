FROM python:3.13.0rc1-alpine
RUN apk add --no-cache bash
WORKDIR /app
COPY setup.cfg setup.py README.md CHANGELOG.md ./
COPY sceptre/ ./sceptre
RUN pip install .
WORKDIR /project
ENTRYPOINT ["sceptre"]
