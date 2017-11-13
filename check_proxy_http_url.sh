#!/bin/bash
################################################################################
# This plugin is an alternative to standard check_http, which doesn't handles
# well the combination of 302/follow and blocked URL on proxy server. Timeout
# doesn't occur, making it difficult to validate that the URL is indeed blocked
# by the proxy server
# Can be used with cntlm (cntlm -H -c /etc/cntlm.conf)
################################################################################
#Nagios Constants
OK=0
WARNING=1
CRITICAL=2
UNKNOWN=3

#Set to unknown in case of unplaned exit
FINAL_STATE=$UNKNOWN
FINAL_COMMENT="UNKNOWN: Unplaned exit. You should check that everything is alright"

#Default values
ENABLE_PERFDATA=0
VERBOSE=0
WGET_BIN="/usr/bin/wget"

#Process arguments. Add proper options and processing
while getopts ":vru:p:" opt; do
        case $opt in
                v)
                        echo "Verbose mode ON"
                        echo
                        VERBOSE=1
                        ;;
                r)
                        REVERSE=1
                        ;;
                u)
                        TARGET_URL=$OPTARG
                        ;;
                p)
                        PROXY_ADDRESS_PORT=$OPTARG
                        ;;
                \?)
                        #TODO %USAGE
                        echo "Invalid option: -$OPTARG
Usage = $0 -u TARGET_URL [-p PROXY_ADDRESS:PROXY_PORT] [-r] [-v]"
                        exit $UNKNOWN
                        ;;
                :)
                        #TODO %USAGE
                        echo "UNKNOWN: Option -$OPTARG requires an argument.
Usage = $0 -u TARGET_URL [-p PROXY_ADDRESS:PROXY_PORT] [-r] [-v]"
                        exit $UNKNOWN
                        ;;
        esac
done

if [[ -z $TARGET_URL ]] ; then
        #TODO %USAGE
        echo "UNKNOWN: Usage = $0 -u TARGET_URL [-p PROXY_ADDRESS:PROXY_PORT] [-r] [-v]"
        exit $UNKNOWN
fi

#Configure proxy is provided
#If CNTLM is used it's not needed because CNTLM configures it for you
export http_proxy=$PROXY_ADDRESS_PORT

#Check the URL
WGET_OUTPUT=`$WGET_BIN --delete-after --server-response $TARGET_URL 2>&1 | awk '/^  HTTP/{print $2}' | tail -1`
#Beware in case, there is a space caracter before HTTP/1.0
case $WGET_OUTPUT in
        "200")
                #URL is responding
                if [[ $REVERSE ]]; then
                        FINAL_COMMENT="CRITICAL: URL $TARGET_URL is available and it shouldn't - $WGET_OUTPUT"
                        FINAL_STATE=$CRITICAL
                else
                        FINAL_COMMENT="OK: URL $TARGET_URL is available and it should - $WGET_OUTPUT"
                        FINAL_STATE=$OK
                fi
                ;;
        "403" | "503")
                #URL is not responding
                if [[ $REVERSE ]]; then
                        FINAL_COMMENT="OK: URL $TARGET_URL isn't available and it shouldn't - $WGET_OUTPUT"
                        FINAL_STATE=$OK
                else
                        FINAL_COMMENT="CRITICAL: URL $TARGET_URL isn't available and it should - $WGET_OUTPUT"
                        FINAL_STATE=$CRITICAL
                fi
                ;;
        "407")
                #Authentication required
                FINAL_STATE=$UNKNOWN
                FINAL_COMMENT="UNKNOWN: Proxy has denied authentication, check your credentials or cntlm proxy"
                ;;
        *)
                FINAL_STATE=$UNKNOWN
                FINAL_COMMENT="UNKNOWN: HTML Return Code '$WGET_OUTPUT' isn't supported yet"
                ;;
esac

#Script end, display verbose information
if [[ $VERBOSE -eq 1 ]] ; then
        echo "Variables:"
        #Add all your variables at the en of the "for" line to display them
        for i in WGET_BIN TARGET_URL PROXY_ADDRESS_PORT REVERSE WGET_OUTPUT
        do
                echo -n "$i: "
                eval echo \$${i}
        done
        echo
fi

echo ${FINAL_COMMENT}${PERFDATA}
exit $FINAL_STATE
