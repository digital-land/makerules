ARG REPO=public.ecr.aws/l6z6v3j6/
FROM ${REPO}digital-land-python:latest

COPY . /pipeline

# TODO add labels?

RUN make init

ENTRYPOINT ["make"]
