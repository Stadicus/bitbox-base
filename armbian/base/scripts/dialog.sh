#!/bin/bash

abort() {
    clear
    exit 0
}
trap 'abort' SIGHUP SIGINT SIGTERM

if [[ ${UID} -ne 0 ]]; then
    echo "ERR: script needs to be run as superuser."
    exit 1
fi

DIALOGRC='/opt/shift/config/dialog/.dialogrc'
export DIALOGRC

backtitle="BitBoxBase: Maintenance"
box_h=18
box_w=60

popup_h=8
popup_w=36


#
# check credentials
# -----------------------------------------------------------------------------
while true; do
    if /opt/shift/scripts/bbb-cmd.sh flashdrive mount &>/dev/null; then
        echo "MAINTENANCE: flashdrive mounted to check credentials"

        # are all necessary files for a reset present?
        if [[ -f /mnt/backup/.maintenance-token ]] && [[ -f /data/maintenance-token-hashes ]]; then
            private_token_hash="$(sha256sum /mnt/backup/.maintenance-token | cut -f 1 -d " ")"
            break
        else
            dialog  --title "Maintenance: Not authorized" --backtitle "${backtitle}" --ok-label "Reload" \
                    --msgbox "\nThis flashdrive does not contain a valid maintenance token." ${popup_h} ${popup_w}
        fi

    else
        dialog  --title "Maintenance: No flashdrive" --backtitle "${backtitle}" --ok-label "Reload" \
                --msgbox "\nPlease plug the backup flashdrive into the BitBoxBase." ${popup_h} ${popup_w}
    fi
done

# check for token prefix 'factory' and ask for additional password
if grep -q "factory-" /mnt/backup/.maintenance-token; then
    msg="\n
    Welcome to BitBoxBase maintenance. \n\n
    A valid factory maintenance token has been found. \n\n
    Please enter password:
    "
    if ! password=$(dialog --title "Main menu" --backtitle "${backtitle}" --insecure --passwordbox "${msg}" ${box_h} ${box_w}  3>&1 1>&2 2>&3); then
        abort
    fi
    # factory token: calculate public_token from sha256sum(password-private_token_hash)
    public_token=$(sha256sum <<< "${password}-${private_token_hash}" | tr -d "[:space:]-")
else
    # user token: calculate public_token from sha256sum(private_token_hash)
    public_token=$(sha256sum <<< "${private_token_hash}" | tr -d "[:space:]-")
fi

if ! grep -q "${public_token}" /data/maintenance-token-hashes || [[ ${#public_token} -ne 64 ]]; then
    dialog --title "${backtitle}" --msgbox "\nInvalid token or wrong password.\n\nRestart device and try again." 10 40
    abort
fi

#
# Submenu: SSD presync
# -----------------------------------------------------------------------------
submenu_presync() {
    while true; do
        if ! menuitem=$(dialog --title "SSD presync" --backtitle "${backtitle}" --menu "\nPlease choose maintenance task" ${box_h} ${box_w} 10 \
                1 "CREATE snapshot on external storage" \
                2 "IMPORT snapshot to internal ssd" \
            3>&1 1>&2 2>&3)
            then break
        fi

        case $menuitem in
            1)  # create snapshot
                count=0
                unset options

                while read -r partition; do
                    count=$((count + 1));
                    options[$count]="${partition} off"
                done <<< "$(lsblk -o NAME,SIZE,TYPE -arnp -e 1,7,31,179,252 | grep part | cut -f 1,2 -d " ")"

                options=(${options[@]})
                cmd=(dialog --title "Create snapshot" --backtitle "${backtitle}" --radiolist "Select target drive:" 22 76 16)
                target_drive=$("${cmd[@]}" "${options[@]}" 3>&1 1>&2 2>&3)

                if ! bbb-cmd.sh presync create "${target_drive}" | dialog --title "Main menu" --backtitle "${backtitle}" --progressbox "Creating snapshot on ${target_drive}..." 40 60; then
                    dialog  --title "ERR" --msgbox "\nError." ${popup_h} ${popup_w}
                else
                    dialog  --title "Snapshot created" --msgbox "\nPresync snapshot created." ${popup_h} ${popup_w}
                fi
                ;;

            2)  # import snapshot

                # select source drive
                count=0
                unset options

                while read -r partition; do
                    count=$((count + 1));
                    options[$count]="${partition} off"
                done <<< "$(lsblk -o NAME,SIZE,TYPE -arnp -e 1,7,31,179,252 | grep part | cut -f 1,2 -d " ")"

                options=(${options[@]})
                cmd=(dialog --title "Restore snapshot" --backtitle "${backtitle}" --radiolist "Select source drive:" 22 76 16)
                source_drive=$("${cmd[@]}" "${options[@]}" 3>&1 1>&2 2>&3)

                # select file
                count=0
                unset options

                while read -r partition; do
                    count=$((count + 1));
                    options[$count]="${partition} off"
                done <<< "$(stat -c "%n %s" /mnt/ext/bbb-presync*)"

                options=(${options[@]})
                cmd=(dialog --title "Restore snapshot" --backtitle "${backtitle}" --radiolist "Select target drive:" 22 76 16)
                source_file=$("${cmd[@]}" "${options[@]}" 3>&1 1>&2 2>&3)

                if ! bbb-cmd.sh presync restore "${source_drive}" "${source_file}" | dialog --title "Main menu" --backtitle "${backtitle}" --progressbox "Restoring snapshot..." 40 60; then
                    dialog  --title "ERR" --msgbox "\nError." ${popup_h} ${popup_w}
                else
                    dialog  --title "Snapshot restored" --msgbox "\nPresync snapshot restored." ${popup_h} ${popup_w}
                fi
                ;;
            *)
                break
        esac
    done
}

#
# Submenu: Factory reset
# -----------------------------------------------------------------------------
submenu_reset() {
    while true; do
        if ! menuitem=$(dialog --title "SSD presync" --backtitle "${backtitle}" --menu "\nPlease choose maintenance task" ${box_h} ${box_w} 10 \
                1 "AUTHENTICATION reset..." \
                2 "[wip] CONFIGURATION reset..." \
                3 "[wip] DISK IMAGE reset..." \
                4 "[wip] WIPE SSD..." \
            3>&1 1>&2 2>&3)
            then break
        fi

        case $menuitem in
            1)  # auth
                dialog --title "DEBUG" --backtitle "${backtitle}" --msgbox "AUTH" 10 ${box_w}
                ;;
        esac
    done
}

#
# Main menu
# -----------------------------------------------------------------------------
while true; do

# Main menu
if ! menuitem=$(dialog --title "Main menu" --backtitle "${backtitle}" --menu "\nPlease choose maintenance task" ${box_h} ${box_w} 10 \
        1 "SSD presync data..." \
        2 "Wipe factory setup credentials" \
        3 "Factory reset..." \
        4 "Shutdown" \
    3>&1 1>&2 2>&3)
    then abort
fi

case $menuitem in
	1)  # presync internal ssd
        submenu_presync
        ;;

	2)  # wipe factory setup credentials
        dialog --title "DEBUG" --msgbox "WIPE" 10 ${box_w}
        ;;

	3)  # factory reset (submenu)
        submenu_reset
        ;;

	4)  # shutdown
        if dialog --title "${backtitle}" --yesno "\n    Shut down BitBoxBase?" 8 40; then
            shutdown now
        fi
        ;;
esac

done

# -----------------------------------------------------------------------------

exit 0

clear