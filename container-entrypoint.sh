#!/bin/sh
set -eu

. /venv/bin/activate

CMD="${1:-radicale}"
if [ "$CMD" = "radicale" ]; then
  set -- gunicorn --bind '0.0.0.0:5232' --workers "$(nproc)" --env 'RADICALE_CONFIG=/etc/radicale/config' radicale
fi

exec "$@"