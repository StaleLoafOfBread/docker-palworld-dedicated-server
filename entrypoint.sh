#!/bin/bash
# shellcheck disable=SC1091

set -e

APP_USER=steam
APP_GROUP=steam
APP_HOME=/home/$APP_USER

source /includes/colors.sh

# Changes the ownership to $PUID:$PGID for the given file / recursively to the given folder
change_ownership() {
    local target="$1"

    # Find files or directories not owned by specified user and group
    files_with_incorrect_permissions=$(find "$target" ! -user "$PUID" -o ! -group "$PGID")

    if [ -z "$files_with_incorrect_permissions" ]; then
        ei "> All items in $target are already owned by $PUID:$PGID."
    else
        # Echo the total count of files_with_incorrect_permissions
        count=$(echo "$files_with_incorrect_permissions" | wc -l)
        ei "> Found $count items with improper permissions"

        # Echo the files_with_incorrect_permissions to stdout
        ei "> Files with incorrect permissions:"
        ei "> $files_with_incorrect_permissions"

        # Check if running as root and warn user if not
        if [ "$EUID" -ne 0 ]; then
            ew "> Changing ownership may not work as intended unless ran as root"
        fi

        # Change ownership recursively to specified user and group
        ei "> Changing ownership..."
        chown -R "$PUID:$PGID" "$target"

        echo "> Ownership changed to $PUID:$PGID for all items in $target."
    fi
}

if [[ "${PUID}" -eq 0 ]] || [[ "${PGID}" -eq 0 ]]; then
    ee ">>> Running as root is not supported, please fix your PUID and PGID!"
    exit 1
elif [[ "$(id -u steam)" -ne "${PUID}" ]] || [[ "$(id -g steam)" -ne "${PGID}" ]]; then
    ew "> Current $APP_USER user PUID is '$(id -u steam)' and PGID is '$(id -g steam)'"
    ew "> Setting new $APP_USER user PUID to '${PUID}' and PGID to '${PGID}'"
    groupmod -g "${PGID}" "$APP_GROUP" && usermod -u "${PUID}" -g "${PGID}" "$APP_USER"
else
    ew "> Current $APP_USER user PUID is '$(id -u steam)' and PGID is '$(id -g steam)'"
    ew "> PUID and PGID matching what is requested for user $APP_USER"
fi

change_ownership "$APP_HOME"
change_ownership "$APP_HOME"
change_ownership "$GAME_ROOT"
change_ownership /entrypoint.sh
change_ownership /scripts
change_ownership /includes

ew_nn "> id steam: " ; e "$(id steam)"

exec gosu $APP_USER:$APP_GROUP "$@"
