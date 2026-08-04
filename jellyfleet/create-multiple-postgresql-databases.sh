#!/usr/bin/env bash

set -Eeuo pipefail

additional_databases="${POSTGRES_ADDITIONAL_DATABASES:-}"

if [[ -z "$additional_databases" ]]; then
    echo "No additional databases requested."
    
else
    IFS=',' read -ra databases <<< "$additional_databases"

    for database in "${databases[@]}"; do
        # Trim leading and trailing whitespace.
        database="${database#"${database%%[![:space:]]*}"}"
        database="${database%"${database##*[![:space:]]}"}"

        [[ -z "$database" ]] && continue

        echo "Ensuring database '$database' exists..."

        psql \
            --username "$POSTGRES_USER" \
            --dbname postgres \
            --set ON_ERROR_STOP=1 \
            --set database="$database" \
            --set owner="$POSTGRES_USER" <<'EOSQL'
                SELECT format(
                    'CREATE DATABASE %I OWNER %I',
                    :'database',
                    :'owner'
                )
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM pg_database
                    WHERE datname = :'database'
                )
                \gexec
EOSQL
    done

    echo "All additional databases processed."
fi