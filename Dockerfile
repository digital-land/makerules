ARG REPO=public.ecr.aws/l6z6v3j6/
FROM ${REPO}digital-land-python:latest

COPY . /pipeline

# TODO add labels?

RUN set -xe; \
    [ -f /pipeline/requirements.txt ] && /opt/venv/bin/pip install --upgrade -r requirements.txt; \
    [ -f /pipeline/setup.py ] && /opt/venv/bin/pip install -e ".${PIP_INSTALL_PACKAGE:-test}"

ENTRYPOINT ["make"]
