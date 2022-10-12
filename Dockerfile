FROM python:3.10-slim as python-base

ARG APP_USER=django \
    APP_VERSION=unknown \
    APP_PATH=/app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONFAULTHANDLER=1 \
    PYTHONUNBUFFERED=1

RUN groupadd --system ${APP_USER} && \
    useradd --no-log-init --system --gid ${APP_USER} ${APP_USER}

#
# Python build stage
#
FROM python-base AS python-build

ARG APP_PATH

ARG BUILD_DEPS="build-essential libpq-dev"
RUN apt-get update && \
    apt-get install --no-install-recommends -y $BUILD_DEPS && \
    rm -rf /var/lib/apt/lists/*

WORKDIR ${APP_PATH}

COPY poetry.lock pyproject.toml .
RUN pip install poetry && \
    poetry export --without=dev -n -f requirements.txt -o requirements.txt && \
    pip install -r requirements.txt

#
# Python run stage
#
FROM python-base as python-run

ARG APP_PATH
ARG APP_USER

ARG RUN_DEPS="postgresql-client"
RUN apt-get update && \
    apt-get install --no-install-recommends -y $RUN_DEPS && \
    rm -rf /var/lib/apt/lists/*

WORKDIR ${APP_PATH}

COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

RUN chown -R ${APP_USER}:${APP_USER} ${APP_PATH}

USER $APP_USER:$APP_USER

ENV PATH="${APP_PATH}/.venv/bin:$PATH"
ENV STATIC_ROOT="${APP_PATH}/staticroot"

COPY --from=python-build /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=python-build /usr/local/bin /usr/local/bin
COPY . .

RUN mkdir -p ${APP_PATH}/staticroot
RUN python manage.py collectstatic --noinput

EXPOSE 8000

ENTRYPOINT /docker-entrypoint.sh $0 $@
CMD ["production"]
