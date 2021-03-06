#!/usr/bin/env bash

export LC_LANG=en_US.utf8

CRT_PATH="/etc/letsencrypt/live"
TMP_LIST=$(ls ${CRT_PATH})
CRT_LIST=()
CRT_LIST_DISABLED=()
SORTED=()
WEBSRV="nginx"
DBU=15

for d in ${TMP_LIST[@]}; do
    if [ -d "${CRT_PATH}/${d}" ]; then
        CRT_LIST+=("${d}")
    fi
done

for x in ${CRT_LIST[@]}; do
    skip=
    for y in ${CRT_LIST_DISABLED[@]}; do
        [[ $x == $y ]] && { skip=1; break; }
    done
    [[ -n $skip ]] || SORTED+=("${x}")
done

source /opt/do-certupdate/bin/activate

for i in ${SORTED[@]}; do
    CERT=/etc/letsencrypt/live/${i}/cert.pem

    EXPD=`openssl x509 -enddate -noout -in ${CERT} | awk -F'=' '{print $2}'`
    CERTD="date +%D --date='${EXPD}'"
    ED=`eval ${CERTD}`
    TODAYD=$(date -d "+${DBU} days")

    if [ "`date -d "${ED}" +%s`" -le "`date -d "${TODAYD}" +%s`" ]; then
        echo "Certificate: ${i} will be updated."
        certbot certonly --dns-digitalocean --dns-digitalocean-credentials /usr/share/do-certupdate/.do.ini --register-unsafely-without-email --force-renewal -d ${i}
        systemctl restart ${WEBSRV}
    fi
done

deactivate
