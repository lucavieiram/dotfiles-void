#!/usr/bin/env bash
# Umami numbers without the dashboard.
#
# Reads Postgres over ssh instead of the HTTP API. The API surface moved between
# Umami 2.x and 3.x and its event-property endpoints return nothing, while the
# Events widget in the UI is broken outright in 3.2.0. The schema is the stable
# part - the dashboard is just one reader of it.
#
#   umami-stats.sh        last 7 days
#   umami-stats.sh 1      today
#   umami-stats.sh 30     last 30 days
#   umami-stats.sh 0      everything
set -euo pipefail

HOST=${UMAMI_SSH_HOST:-dun}
DAYS=${1:-7}

if [ "$DAYS" = "0" ]; then
    WINDOW="TRUE"; LABEL="desde o inicio"
else
    WINDOW="e.created_at >= now() - interval '${DAYS} days'"; LABEL="ultimos ${DAYS} dias"
fi

printf '\n\033[1mCecilia Pascoal\033[0m  (%s)\n\n' "$LABEL"

ssh -o BatchMode=yes "$HOST" \
    "docker exec -i umami-db psql -U umami -d umami -q -P pager=off" <<SQL
\pset border 2
\echo '-- visitas --'
SELECT count(DISTINCT e.session_id) AS visitantes,
       count(*) FILTER (WHERE e.event_type = 1) AS pageviews
FROM website_event e WHERE ${WINDOW};

\echo ''
\echo '-- cliques por origem --'
SELECT e.event_name AS evento,
       coalesce(d.string_value, '(sem origem)') AS origem,
       count(*) AS cliques
FROM website_event e
LEFT JOIN event_data d
       ON d.website_event_id = e.event_id AND d.data_key = 'origem'
WHERE e.event_type = 2 AND ${WINDOW}
GROUP BY 1, 2
ORDER BY 3 DESC, 1, 2;

\echo ''
\echo '-- taxa de conversao --'
-- The number that actually matters: of the people who looked, how many reached
-- out. Visits are vanity; this is the business.
SELECT count(DISTINCT e.session_id) FILTER (WHERE e.event_type = 1) AS viram,
       count(DISTINCT e.session_id) FILTER (WHERE e.event_type = 2) AS clicaram,
       round(100.0 * nullif(count(DISTINCT e.session_id) FILTER (WHERE e.event_type = 2), 0)
             / nullif(count(DISTINCT e.session_id) FILTER (WHERE e.event_type = 1), 0), 1) AS pct
FROM website_event e WHERE ${WINDOW};
SQL
echo
