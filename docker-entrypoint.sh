#!/usr/bin/env bash

set -Eeuo pipefail

help() {
  echo "Usage:"
  echo ""

  echo "development -- start django dev server (for local development)"
  echo ""
  echo "production -- start django via gunicorn"
  echo ""
  echo "tests -- run tests"
}

tests() {
  echo "Unimplemented.  Currently it's defined directly in the CircleCI, but defining it here would make it possible to run the tests exactly the same on one's laptop as it's done in CircleCI."
}

generic() {
  echo "Starting service (${APP_VERSION}) - $@"
}

case "$1" in
  development)
    python manage.py runserver
    ;;
  production)
    gunicorn demoproject.wsgi:application -b 0.0.0.0:8000
    ;;
  migrate)
    python manage.py migrate
    ;;
  *)
    generic "$@"
    ;;
esac
