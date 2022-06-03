#!/bin/sh

. ${HOME}/bin/common_env.sh

check_env $1

CURRENT_DOMAIN="______$RANDOM"
IDENT="    "

NAME=$2
APPNAME=$3
VHOSTNAME=$4

if [ ! -z ${APPNAME} ] && [ ! -z ${VHOSTNAME} ]; then
  IDENT="${IDENT}${IDENT}${IDENT}"
fi

TRANSACTION="DESCRIBE(${NAME})"
TABU_SERVERS="AdminServer"

IS_DOMAIN=0
IS_CLUSTER=0
IS_SERVER=0
IS_VIRTUALHOST=0
IS_APPLICATION=0
IS_FRONTEND=0

if [ -z $SSH_TTY ]; then
  cat << EOF
<HTML>
<HEAD>
<STYLE>
body
{
  color: #484848;
  background: #FFFFFF;
}

.domain_version
{
  font: bold 15px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif, color: #0000FF;
}

.timestamp
{
  font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
}

.object_type
{
  font: bold 15px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
  border: 1px solid #C1DAD7;
  padding: 3px 3px 3px 3px;
  background: #F5FAFA;
  color: #0099FF;
}

li
{
  font: 15px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
  padding: .3em .3em .3em 0;
  list-style-type: none;
}

.list a
{
  position: relative;
  padding: .3em .3em .3em .5em;
  margin: .5em .5em .5em 0;
  color: #0000FF;
  text-decoration: none;
  font-weight: bold;
}

.list a:hover
{
  text-decoration: underline;
}

</STYLE>
<TITLE>Describe</TITLE>
</HEAD>
<BODY>
EOF

  echo "<CENTER><H3>DOMAINS [`echo ${ENV} | tr [a-z] [A-Z]`]</H3></CENTER>"
  echo "<UL class=\"list\">"
fi

if [ -z ${NAME} ]; then
  info Displaying all info on the known farm
  DOMAIN_LIST=`list_all_domains ${ENV}`
  VIRTUALHOST_LIST=`list_all_virtualhosts ${ENV}`
  NAME="__________$RANDOM"
  IS_DOMAIN=1
  IS_VIRTUALHOST=1
else
  if domain_exists ${ENV} ${NAME}
  then
    DOMAIN_LIST=${NAME}
    info ${NAME} is a domain name
    IS_DOMAIN=1
  elif cluster_exists ${ENV} ${NAME}
  then
    DOMAIN_LIST="`target_domain ${ENV} ${NAME}`"
    info "${NAME} is a cluster name in domain(s) `echo "${DOMAIN_LIST}"`"
    IS_CLUSTER=1
  elif server_exists ${ENV} ${NAME}
  then
    DOMAIN_LIST=`target_domain ${ENV} ${NAME}`
    info "${NAME} is a server name in domain(s) `echo "${DOMAIN_LIST}"`"
    IS_SERVER=1
  elif machine_exists ${ENV} ${NAME}
  then
    info "${NAME} is a machine name"
  elif virtualhost_exists ${ENV} ${NAME}
  then
    VIRTUALHOST_LIST="${NAME}"
    DOMAIN_LIST=""
    info "${NAME} is a virtual host name"
    IS_VIRTUALHOST=1
  elif application_exists ${ENV} ${NAME}
  then
    VIRTUALHOST_LIST=`list_all_application_virtualhosts ${ENV} ${NAME}`
    DOMAIN_LIST=""
    info "${NAME} is an application name"
    IS_APPLICATION=1
  elif frontend_exists ${ENV} ${NAME}
  then
    DOMAIN_LIST=""
    info "${NAME} is a frontend name"
    IS_FRONTEND=1
  else
    failure Can\'t understand what ${NAME} is... Call $0 with no arguments to obtain all artifacts.
  fi
fi

# Process domain, cluster and server entries
if [ ${IS_DOMAIN} -gt 0 ] || [ ${IS_CLUSTER} -gt 0 ] || [ ${IS_SERVER} -gt 0 ]; then
  if [ ! -z $SSH_TTY ]; then
    echo DOMAINS
  fi

  for domain in ${DOMAIN_LIST}; do
    DOMAIN=`echo ${domain} | cut -d\. -f 1`

    if [ ${CURRENT_DOMAIN} != ${DOMAIN} ]; then
      if [ -z $SSH_TTY ]; then
        echo -e "  <LI><SPAN CLASS=\"object_type\">D</SPAN><A HREF=\"`get_domain_url ${ENV} ${DOMAIN}`\" TARGET=\"_blank\">${DOMAIN}</A><SPAN CLASS=\"domain_version\">(WLS `get_domain_version ${ENV} ${DOMAIN}`)</SPAN></LI>\n  <UL>"
      else
        echo "[D] ${DOMAIN} `get_domain_url ${ENV} ${DOMAIN}` (WLS `get_domain_version ${ENV} ${DOMAIN}`)"
      fi
    fi

    OBJECTS_LIST=`list_all_servers_with_clusters_and_machines ${ENV} ${DOMAIN}`
    CLUSTER_LIST=`echo -e "${OBJECTS_LIST}" | cut -d\: -f 3 | sort | uniq | sed '/^$/d'`
    SERVER_LIST=`echo -e "${OBJECTS_LIST}" | cut -d\: -f 1`
    TARGET_LIST="${CLUSTER_LIST}\n${SERVER_LIST}"

    for target in `echo -e "${TARGET_LIST}"`; do
      if cluster_exists ${ENV} ${target}
      then
        if [ -z $SSH_TTY ]; then
          CLASS=`echo "    <LI><SPAN CLASS=\"object_type\">C</SPAN> "`
        else
          CLASS="C"
        fi

        CLUSTER_SERVERS=`echo -e "${OBJECTS_LIST}" | grep -w ${target} | cut -d\: -f 1 | sort`

        for SERVER in `echo -e "${CLUSTER_SERVERS}"`; do
          CLUSTER_SERVERS_TMP="${CLUSTER_SERVERS_TMP} ${SERVER}:"`echo -e "${OBJECTS_LIST}" | grep -w ${SERVER} | cut -d\: -f 4`
        done

        if [ -z $SSH_TTY ]; then
          EXTRA_NFO="{`echo ${CLUSTER_SERVERS_TMP} |xargs echo|sed 's/ /, /g'`}"
        else
          EXTRA_NFO="{`echo ${CLUSTER_SERVERS_TMP} |xargs echo|sed 's/ /, /g'`}"
        fi

        CLUSTER_SERVERS_TMP=""

        TABU_SERVERS="${TABU_SERVERS} $CLUSTER_SERVERS"

        if [ ${IS_CLUSTER} -gt 0 ]; then
          if [ ${target} != ${NAME} ]; then
            continue
          fi
        fi

        if [ ${IS_SERVER} -gt 0 ]; then
          if ! element_exists ${NAME} ${CLUSTER_SERVERS}
          then
            continue;
          fi
        fi
      else
        if [ -z $SSH_TTY ]; then
          CLASS=`echo -e "    <LI><SPAN CLASS=\"object_type\">S</SPAN> "`
        else
          CLASS="S"
        fi

        unset CLUSTER_SERVERS
        unset EXTRA_NFO

        if element_exists $target ${TABU_SERVERS}
        then
          continue
        fi

        if [ ${IS_CLUSTER} -gt 0 ]; then 
          continue
        fi
        if [ ${IS_SERVER} -gt 0 ]; then
          if [ ${target} != ${NAME} ]; then
            continue;
          fi
        fi
      fi

      if [ -z $SSH_TTY ]; then
        echo "${CLASS} ${target} ${EXTRA_NFO}</LI>"
      else
        echo "${IDENT}[${CLASS}] ${target} ${EXTRA_NFO}"
      fi

      APPLICATIONS=`list_all_target_applications ${ENV} ${target}`

      if [ -z $SSH_TTY ]; then
        echo "    <UL>"
      fi

      if [ "ZZ${APPLICATIONS}" = "ZZ" ]; then
        if [ -z $SSH_TTY ]; then
          echo -e "      <LI><SPAN CLASS=\"object_type\">A</SPAN> ** TARGET IS FREE </LI>\n    </UL>"
        else
          echo "${IDENT}${IDENT}[A] ** TARGET IS FREE **"
        fi
      else
        for app in ${APPLICATIONS}; do
          if [ -z $SSH_TTY ]; then
            echo -e "      <LI><SPAN CLASS=\"object_type\">A</SPAN> $app </LI>"
          else
            echo "${APP_STRING}${IDENT}${IDENT}[A] $app"
          fi
        done

        if [ -z $SSH_TTY ]; then
          echo "    </UL>"
        fi
      fi

      unset APPLICATIONS
    done

    if [ -z $SSH_TTY ]; then
      echo "  </UL><BR>"
    fi

    CURRENT_DOMAIN=${DOMAIN}
  done

  if [ -z $SSH_TTY ]; then
    echo "</UL>"
  fi
fi

# Process virtualhost entries
if [ ${IS_VIRTUALHOST} -gt 0 ] || [ ${IS_APPLICATION} -gt 0 ]; then
  if [ -z $SSH_TTY ]; then
    echo -e "<CENTER><H3>VIRTUALHOSTS</H3></CENTER>\n<UL class="list">"
  else
    echo VIRTUALHOSTS
  fi

  for virtual_host in ${VIRTUALHOST_LIST}; do
    VIRTUAL_HOST=${virtual_host}
    VIRTUALHOST_APPLICATIONS=`list_all_applications ${ENV} ${VIRTUAL_HOST}`
    FRONTEND_LIST=`get_application_frontend_list ${ENV} ${VIRTUALHOST_APPLICATIONS} | sed 's/\ /, /g'`

    if [ -z $SSH_TTY ]; then
      echo  "  <LI><SPAN CLASS=\"object_type\">V</SPAN> ${VIRTUAL_HOST} {${FRONTEND_LIST}}"
    else
      echo "[V] ${VIRTUAL_HOST} {${FRONTEND_LIST}}"
    fi

    APPLICATION_COUNT=0

    if [ -z $SSH_TTY ]; then
      echo  "  <UL>"
    fi

    for application in $VIRTUALHOST_APPLICATIONS; do
      if [ ${IS_APPLICATION} -gt 0 ]; then
        if [ ${application} != ${NAME} ]; then
          continue
        fi
      fi

      APPLICATION=${application}
      APPTARGETS="`list_all_application_targets ${ENV} ${APPLICATION}`"

      if [ -z "${APPTARGETS}" ]; then
        if [ -z $SSH_TTY ]; then
          echo  "  <LI><SPAN CLASS=\"object_type\">A</SPAN> ${APPLICATION} ** NO TARGETS DEFINED YET (use target_add.sh) **</LI>"
        else
          echo "${IDENT}[A] ${APPLICATION} ** NO TARGETS DEFINED YET (use target_add.sh) **"
        fi
      else 
        if [ -z $SSH_TTY ]; then
          echo "  <LI><SPAN CLASS=\"object_type\">A</SPAN><a href=\"http://${VIRTUAL_HOST}/\">${APPLICATION}</a> {${APPTARGETS}}</LI>"
        else
          echo "${IDENT}[A] ${APPLICATION} {${APPTARGETS}}"
        fi
      fi

      for target in ${APPTARGETS}; do
        if [ -z $SSH_TTY ]; then
          echo -e "  <UL>\n    <LI>Details: describe.sh ${ENV} ${target}</LI>\n  </UL>"
        else
          echo "${IDENT}${IDENT}${IDENT}Details: describe.sh ${ENV} ${target}"
        fi
      done

      APPLICATION_COUNT=`expr ${APPLICATION_COUNT} + 1`
    done

    if [ ${APPLICATION_COUNT} -lt 1 ]; then
      if [ -z $SSH_TTY ]; then
        echo "  <LI><SPAN CLASS=\"object_type\">A</SPAN> ** NO APPLICATIONS ON VIRTUAL HOST YET (use application_add.sh) **</LI>"
      else
        echo "${IDENT}${IDENT}** NO APPLICATIONS ON VIRTUAL HOST YET (use application_add.sh) **"
      fi
    fi

    if [ -z $SSH_TTY ]; then
      echo "  </UL>"
    fi
  done

  if [ -z $SSH_TTY ]; then
    echo -e "</UL>\n<BR>"
    echo "<P ALIGN="right"><SPAN CLASS=\"timestamp\">Generated: `date '+%d/%m/%Y - %H:%M'`</SPAN></P>"
  fi
fi

if [ -z $SSH_TTY ]; then
  echo -e "</BODY>\n</HTML>"
fi

success $*
