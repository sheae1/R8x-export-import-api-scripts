#!/bin/bash
#
# SCRIPT Object count totals
#
ScriptVersion=00.26.01
ScriptDate=2017-10-27

#

export APIScriptVersion=v00x26x01
ScriptName=cli_api_get_object_totals

# =================================================================================================
# =================================================================================================
# START script
# =================================================================================================
# =================================================================================================


# MODIFIED 2017-08-28 -\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

# =================================================================================================
# -------------------------------------------------------------------------------------------------
# START Initial Script Setup
# -------------------------------------------------------------------------------------------------


echo
echo 'Script:  '$ScriptName'  Script Version: '$APIScriptVersion

# -------------------------------------------------------------------------------------------------
# Handle important basics
# -------------------------------------------------------------------------------------------------

#points to where jq is installed
#Apparently MDM, MDS, and Domains don't agree on who sets CPDIR, so better to check!
#export JQ=${CPDIR}/jq/jq
if [ -r ${CPDIR}/jq/jq ] 
then
    export JQ=${CPDIR}/jq/jq
elif [ -r /opt/CPshrd-R80/jq/jq ]
then
    export JQ=/opt/CPshrd-R80/jq/jq
else
    echo "Missing jq, not found in ${CPDIR}/jq/jq or /opt/CPshrd-R80/jq/jq"
    exit 1
fi

export currentapisslport=$(clish -c "show web ssl-port" | cut -d " " -f 2)

export minapiversionrequired=1.0

getapiversion=$(mgmt_cli show api-versions --format json -r true --port $currentapisslport | $JQ '.["current-version"]' -r)
export checkapiversion=$getapiversion
if [ $checkapiversion = null ] ; then
    # show api-versions does not exist in version 1.0, so it fails and returns null
    currentapiversion=1.0
else
    currentapiversion=$checkapiversion
fi

echo 'API version = '$currentapiversion

if [ $(expr $minapiversionrequired '<=' $currentapiversion) ] ; then
    # API is sufficient version
    echo
else
    # API is not of a sufficient version to operate
    echo
    echo 'Current API Version ('$currentapiversion') does not meet minimum API version requirement ('$minapiversionrequired')'
    echo
    echo '! termination execution !'
    echo
    exit 250
fi

if [ x"$APISCRIPTVERBOSE" = x"" ] ; then
    # Verbose mode not set from shell level
    echo
elif [ x"$APISCRIPTVERBOSE" = x"FALSE" ] ; then
    # Verbose mode set OFF from shell level
    echo
else
    echo
    echo 'Script :  '$0
    echo 'Verbose mode set'
    echo
fi


# -------------------------------------------------------------------------------------------------
# END Initial Script Setup
# -------------------------------------------------------------------------------------------------
# =================================================================================================

#
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/-  MODIFIED 2017-08-28



# -------------------------------------------------------------------------------------------------
# Root script declarations
# -------------------------------------------------------------------------------------------------

# ADDED 2017-07-21 -\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

export script_use_publish="FALSE"

export script_use_export="TRUE"
export script_use_import="FALSE"
export script_use_delete="FALSE"

export script_dump_standard="FALSE"
export script_dump_full="FALSE"
export script_dump_csv="FALSE"

export script_use_csvfile="FALSE"

#
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/- ADDED 2017-07-21
# ADDED 2017-08-03 -\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

# Wait time in seconds
export WAITTIME=15

#
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/- ADDED 2017-08-03

# MODIFIED 2017-08-28 \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

# =================================================================================================
# =================================================================================================
# START:  Command Line Parameter Handling and Help
# =================================================================================================


# Code template for parsing command line parameters using only portable shell
# code, while handling both long and short params, handling '-f file' and
# '-f=file' style param data and also capturing non-parameters to be inserted
# back into the shell positional parameters.
#
# Standard Command Line Parameters
#
# -? | --help
# -v | --verbose
# -P <web-ssl-port> | --port <web-ssl-port> | -P=<web-ssl-port> | --port=<web-ssl-port>
# -r | --root
# -u <admin_name> | --user <admin_name> | -u=<admin_name> | --user=<admin_name>
# -p <password> | --password <password> | -p=<password> | --password=<password>
# -m <server_IP> | --management <server_IP> | -m=<server_IP> | --management=<server_IP>
# -d <domain> | --domain <domain> | -d=<domain> | --domain=<domain>
# -s <session_file_filepath> | --session-file <session_file_filepath> | -s=<session_file_filepath> | --session-file=<session_file_filepath>
# -l <log_path> | --log-path <log_path> | -l=<log_path> | --log-path=<log_path>'
#
# -x <export_path> | --export <export_path> | -x=<export_path> | --export=<export_path> 
# -i <import_path> | --import-path <import_path> | -i=<import_path> | --import-path=<import_path>'
# -k <delete_path> | --delete-path <delete_path> | -k=<delete_path> | --delete-path=<delete_path>'
#
# -c <csv_path> | --csv <csv_path> | -c=<csv_path> | --csv=<csv_path>'
#


export SHOWHELP=false
export CLIparm_websslport=443
export CLIparm_rootuser=false
export CLIparm_user=
export CLIparm_password=
export CLIparm_mgmt=
export CLIparm_domain=
export CLIparm_sessionidfile=
export CLIparm_logpath=

export CLIparm_exportpath=
export CLIparm_importpath=
export CLIparm_deletepath=

export CLIparm_csvpath=

export REMAINS=


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

dumpcliparmparseresults () {

	#
	# Testing - Dump aquired values
	#
	if [ x"$APISCRIPTVERBOSE" = x"TRUE" ] ; then
	    # Verbose mode ON
	    
	    export outstring=
	    export outstring=$outstring"Command line parameters after: \n "
	    export outstring=$outstring"CLIparm_rootuser='$CLIparm_rootuser' \n "
	    export outstring=$outstring"CLIparm_user='$CLIparm_user' \n "
	    export outstring=$outstring"CLIparm_password='$CLIparm_password' \n "
	
	    export outstring=$outstring"CLIparm_websslport='$CLIparm_websslport' \n "
	    export outstring=$outstring"CLIparm_mgmt='$CLIparm_mgmt' \n "
	    export outstring=$outstring"CLIparm_domain='$CLIparm_domain' \n "
	    export outstring=$outstring"CLIparm_sessionidfile='$CLIparm_sessionidfile' \n "
	    export outstring=$outstring"CLIparm_logpath='$CLIparm_logpath' \n "
	
	    if [ x"$script_use_export" = x"TRUE" ] ; then
	        export outstring=$outstring"CLIparm_exportpath='$CLIparm_exportpath' \n "
	    fi
	    if [ x"$script_use_import" = x"TRUE" ] ; then
	        export outstring=$outstring"CLIparm_importpath='$CLIparm_importpath' \n "
	    fi
	    if [ x"$script_use_delete" = x"TRUE" ] ; then
	        export outstring=$outstring"CLIparm_deletepath='$CLIparm_deletepath' \n "
	    fi
	    if [ x"$script_use_csvfile" = x"TRUE" ] ; then
	        export outstring=$outstring"CLIparm_csvpath='$CLIparm_csvpath' \n "
	    fi
	    
	    export outstring=$outstring"SHOWHELP='$SHOWHELP' \n "
	    export outstring=$outstring"APISCRIPTVERBOSE='$APISCRIPTVERBOSE' \n "
	    export outstring=$outstring"remains='$REMAINS'"
	    
	    echo
	    echo -e $outstring
	    echo
	    for i ; do echo - $i ; done
	    echo CLI parms - number $# parms $@
	    echo
	    
	fi

}


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------


export cli_api_cmdlineparm_handler=cmd_line_parameters_handler.action.common.001.sh

echo
echo '--------------------------------------------------------------------------'
echo
echo "Calling external Command Line Paramenter Handling Script"
echo

. ./$cli_api_cmdlineparm_handler "$@"

echo
echo "Returned from external Command Line Paramenter Handling Script"
echo

dumpcliparmparseresults "$@"

if [ x"$APISCRIPTVERBOSE" = x"TRUE" ] ; then
    echo
    read -t $WAITTIME -n 1 -p "Any key to continue : " anykey
fi
echo
echo "Starting local execution"
echo
echo '--------------------------------------------------------------------------'
echo


# -------------------------------------------------------------------------------------------------
# Handle request for help and exit
# -------------------------------------------------------------------------------------------------

#
# Was help requested, if so show it and exit
#
if [ x"$SHOWHELP" = x"true" ] ; then
    # Show Help
    # Done in external Script now
    #doshowhelp
    exit
fi

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------


# =================================================================================================
# END:  Command Line Parameter Handling and Help
# =================================================================================================
# =================================================================================================

#
# -------------------------------------------------------------------------------- MODIFIED 2017-08-28


# =================================================================================================
# =================================================================================================
# START:  Setup Standard Parameters
# =================================================================================================

# MODIFIED 2017-08-28 -\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

export gaiaversion=$(clish -c "show version product" | cut -d " " -f 6)

if [ x"$APISCRIPTVERBOSE" = x"TRUE" ] ; then
    echo 'Gaia Version : $gaiaversion = '$gaiaversion
    echo
fi


export DATE=`date +%Y-%m-%d-%H%M%Z`

if [ x"$APISCRIPTVERBOSE" = x"TRUE" ] ; then
    echo 'Date Time Group   :  '$DATE
    echo
fi

#
# \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/-  MODIFIED 2017-08-28


# =================================================================================================
# END:  Setup Standard Parameters
# =================================================================================================
# =================================================================================================


# MODIFIED 2017-07-21 \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

# =================================================================================================
# =================================================================================================
# START:  Setup Login Parameters and Login to Mgmt_CLI
# =================================================================================================


if [ x"$CLIparm_user" != x"" ] ; then
    export APICLIadmin=$CLIparm_user
else
    export APICLIadmin=administrator
fi

if [ x"$CLIparm_sessionidfile" != x"" ] ; then
    export APICLIsessionfile=$CLIparm_sessionidfile
else
    export APICLIsessionfile=id.txt
fi


#
# Testing - Dump aquired values
#
echo 'APICLIadmin       :  '$APICLIadmin
echo 'APICLIsessionfile :  '$APICLIsessionfile
echo

loginstring=
mgmttarget=
domaintarget=

if [ x"$CLIparm_rootuser" = x"true" ] ; then
#   Handle Root User
    loginstring="--root true "
else
#   Handle admin user parameter
    if [ x"$APICLIadmin" != x"" ] ; then
        loginstring="user $APICLIadmin"
    else
        loginstring=$loginstring
    fi
    
#   Handle password parameter
    if [ x"$CLIparm_password" != x"" ] ; then
        if [ x"$loginstring" != x"" ] ; then
            loginstring=$loginstring" password \"$CLIparm_password\""
        else
            loginstring="password \"$CLIparm_password\""
        fi
    else
        loginstring=$loginstring
    fi
fi

if [ x"$CLIparm_domain" != x"" ] ; then
#   Handle domain parameter for login string
    if [ x"$loginstring" != x"" ] ; then
        loginstring=$loginstring" domain \"$CLIparm_domain\""
    else
        loginstring="loginstring \"$CLIparm_domain\""
    fi
else
    loginstring=$loginstring
fi

if [ x"$CLIparm_websslport" != x"" ] ; then
#   Handle web ssl port parameter for login string
    if [ x"$loginstring" != x"" ] ; then
        loginstring=$loginstring" --port $CLIparm_websslport"
    else
        loginstring="--port $CLIparm_websslport"
    fi
else
    loginstring=$loginstring
fi

#   Handle management server parameter for mgmt_cli parms
if [ x"$CLIparm_mgmt" != x"" ] ; then
    if [ x"$mgmttarget" != x"" ] ; then
        mgmttarget=$mgmttarget" -m \"$CLIparm_mgmt\""
    else
        mgmttarget="-m \"$CLIparm_mgmt\""
    fi
else
    mgmttarget=$mgmttarget
fi

#   Handle domain parameter for mgmt_cli parms
if [ x"$CLIparm_domain" != x"" ] ; then
    if [ x"$domaintarget" != x"" ] ; then
        domaintarget=$domaintarget" -d \"$CLIparm_domain\""
    else
        domaintarget="-d \"$CLIparm_domain\""
    fi
else
    domaintarget=$domaintarget
fi

echo
echo 'mgmt_cli Login!'
echo
echo 'Login to mgmt_cli as '$APICLIadmin' and save to session file :  '$APICLIsessionfile
echo

#
# Testing - Dump login string bullt from parameters
#
if [ x"$APISCRIPTVERBOSE" = x"TRUE" ] ; then
    echo 'Execute login with loginstring '\"$loginstring\"
    echo 'Execute operations with domaintarget '\"$domaintarget\"
    echo 'Execute operations with mgmttarget '\"$mgmttarget\"
    echo
fi

if [ x"$mgmttarget" = x"" ] ; then
    mgmt_cli login $loginstring > $APICLIsessionfile
else
    mgmt_cli login $loginstring $mgmttarget > $APICLIsessionfile
fi
EXITCODE=$?
if [ "$EXITCODE" != "0" ] ; then
    
    echo
    echo "mgmt_cli login error!"
    echo
    cat $APICLIsessionfile
    echo
    echo "Terminating script..."
    echo
    exit 255

else
    
    echo "mgmt_cli login success!"
    echo
    cat $APICLIsessionfile
    echo
    
fi


# =================================================================================================
# END:  Setup Login Parameters and Login to Mgmt_CLI
# =================================================================================================
# =================================================================================================

#
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ MODIFIED 2017-07-21
# MODIFIED 2017-07-21 \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

# =================================================================================================
# =================================================================================================
# START:  Setup CLI Parameters
# =================================================================================================


# -------------------------------------------------------------------------------------------------
# Set parameters for Main operations - CLI
# -------------------------------------------------------------------------------------------------

if [ x"$CLIparm_logpath" != x"" ] ; then
    export APICLIlogpathroot=$CLIparm_logpath
else
    export APICLIlogpathroot=./dump
fi

export APICLIlogpathbase=$APICLIlogpathroot/$DATE

if [ ! -r $APICLIlogpathroot ] ; then
    mkdir $APICLIlogpathroot
fi
if [ ! -r $APICLIlogpathbase ] ; then
    mkdir $APICLIlogpathbase
fi

export APICLIlogfilepath=$APICLIlogpathbase/$ScriptName'_'$APIScriptVersion'_'$DATE.log

if [ x"$script_use_export" = x"TRUE" ] ; then
    if [ x"$CLIparm_exportpath" != x"" ] ; then
        export APICLIpathroot=$CLIparm_exportpath
    else
        export APICLIpathroot=./dump
    fi
  
    export APICLIpathbase=$APICLIpathroot/$DATE
    
    if [ ! -r $APICLIpathroot ] ; then
        mkdir $APICLIpathroot
    fi
    if [ ! -r $APICLIpathbase ] ; then
        mkdir $APICLIpathbase
    fi
fi

if [ x"$script_use_import" = x"TRUE" ] ; then
    if [ x"$CLIparm_importpath" != x"" ] ; then
        export APICLICSVImportpathbase=$CLIparm_importpath
    else
        export APICLICSVImportpathbase=./import.csv
    fi
    
    if [ ! -r $APICLIpathbase/import ] ; then
        mkdir $APICLIpathbase/import
    fi
fi

if [ x"$script_use_delete" = x"TRUE" ] ; then
    if [ x"$CLIparm_deletepath" != x"" ] ; then
        export APICLICSVDeletepathbase=$CLIparm_deletepath
    else
        export APICLICSVDeletepathbase=./delete.csv
    fi
    
    if [ ! -r $APICLIpathbase/delete ] ; then
        mkdir $APICLIpathbase/delete
    fi
fi

if [ x"$script_use_csvfile" = x"TRUE" ] ; then
    if [ x"$CLIparm_csvpath" != x"" ] ; then
        export APICLICSVcsvpath=$CLIparm_csvpath
    else
        export APICLICSVcsvpath=./domains.csv
    fi
    
fi

if [ x"$script_dump_csv" = x"TRUE" ] ; then
    if [ ! -r $APICLIpathbase/csv ] ; then
        mkdir $APICLIpathbase/csv
    fi
fi

if [ x"$script_dump_full" = x"TRUE" ] ; then
    if [ ! -r $APICLIpathbase/full ] ; then
        mkdir $APICLIpathbase/full
    fi
fi

if [ x"$script_dump_standard" = x"TRUE" ] ; then
    if [ ! -r $APICLIpathbase/standard ] ; then
        mkdir $APICLIpathbase/standard
    fi
fi

    
# =================================================================================================
# END:  Setup CLI Parameters
# =================================================================================================
# =================================================================================================

#
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ MODIFIED 2017-07-21

# =================================================================================================
# -------------------------------------------------------------------------------------------------
# =================================================================================================
# START:  Main operations - 
# =================================================================================================


# -------------------------------------------------------------------------------------------------
# Set parameters for Main operations
# -------------------------------------------------------------------------------------------------


export APICLIfileexportpre=dump_
export APICLIfileexportext=json
export APICLIfileexportsufix=$DATE'.'$APICLIfileexportext
export APICLICSVfileexportext=csv
export APICLICSVfileexportsufix='.'$APICLICSVfileexportext

export APICLIObjectLimit=500

# =================================================================================================
# START:  Get objects Totals
# =================================================================================================


export APICLIdetaillvl=standard

#export APICLIdetaillvl=full


# -------------------------------------------------------------------------------------------------
# Start executing Main operations
# -------------------------------------------------------------------------------------------------


#export APICLIpathexport=$APICLIpathbase/$APICLIdetaillvl
#export APICLIpathexport=$APICLIpathbase/csv
#export APICLIpathexport=$APICLIpathbase/import
#export APICLIpathexport=$APICLIpathbase/delete
export APICLIfileexportpost='_'$APICLIdetaillvl'_'$APICLIfileexportsufix
export APICLICSVheaderfilesuffix=header
#export APICLIpathexportwip=$APICLIpathexport/wip
#if [ ! -r $APICLIpathexportwip ] 
#then
#    mkdir $APICLIpathexportwip
#fi

echo
echo 'Get Object totals : '
echo


# -------------------------------------------------------------------------------------------------
# Main Operational repeated proceedure - ExportObjectsToCSVviaJQ
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# GetNumberOfObjectsviaJQ
# -------------------------------------------------------------------------------------------------

# The GetNumberOfObjectsviaJQ is the obtains the number of objects for that type indicated.
#

GetNumberOfObjectsviaJQ () {

    export objectstotal=
    export objectsfrom=
    export objectsto=
    
    #
    # Troubleshooting output
    #
    if [ x"$APISCRIPTVERBOSE" = x"TRUE" ] ; then
        # Verbose mode ON
        echo
        echo '$CSVJQparms' - $CSVJQparms
        echo
    fi
    
    objectstotal=$(mgmt_cli show $APICLIobjecttype limit 1 offset 0 details-level "$APICLIdetaillvl" --format json -s $APICLIsessionfile | $JQ ".total")
    errorreturn=$?

    if [ $errorreturn != 0 ] ; then
        # Something went wrong, terminate
        exit $errorreturn
    fi
    
    echo
    return 0
    
    #
}

# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# handle simple objects
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# Objects
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

echo
echo 'Objects'
echo
echo >> $APICLIlogfilepath
echo 'Objects' >> $APICLIlogfilepath
echo >> $APICLIlogfilepath

# -------------------------------------------------------------------------------------------------
# hosts
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=host
export APICLIobjectstype=hosts

objectstotal_hosts=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_hosts="$objectstotal_hosts"
export number_of_objects=$number_hosts

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath

# -------------------------------------------------------------------------------------------------
# networks
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=network
export APICLIobjectstype=networks

objectstotal_networks=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_networks="$objectstotal_networks"
export number_of_objects=$number_networks

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# groups
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=group
export APICLIobjectstype=groups

objectstotal_groups=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_groups="$objectstotal_groups"
export number_of_objects=$number_groups

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# groups-with-exclusion
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=group-with-exclusion
export APICLIobjectstype=groups-with-exclusion

objectstotal_groupswithexclusion=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_groupswithexclusion="$objectstotal_groupswithexclusion"
export number_of_objects=$number_groupswithexclusion

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# address-ranges
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=address-range
export APICLIobjectstype=address-ranges

objectstotal_addressranges=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_addressranges="$objectstotal_addressranges"
export number_of_objects=$number_addressranges

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# multicast-address-ranges
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=multicast-address-range
export APICLIobjectstype=multicast-address-ranges
objectstotal_multicastaddressranges=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_multicastaddressranges="$objectstotal_multicastaddressranges"
export number_of_objects=$number_multicastaddressranges

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# dns-domains
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=dns-domain
export APICLIobjectstype=dns-domains

objectstotal_dnsdomains=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_dnsdomains="$objectstotal_dnsdomains"
export number_of_objects=$number_dnsdomains

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# security-zones
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=security-zone
export APICLIobjectstype=security-zones

objectstotal_securityzones=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_securityzones="$objectstotal_securityzones"
export number_of_objects=$number_securityzones

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# dynamic-objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=dynamic-object
export APICLIobjectstype=dynamic-objects

objectstotal_dynamicobjects=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_dynamicobjects="$objectstotal_dynamicobjects"
export number_of_objects=$number_dynamicobjects

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# simple-gateways
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=simple-gateway
export APICLIobjectstype=simple-gateways

objectstotal_simplegateways=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_simplegateways="$objectstotal_simplegateways"
export number_of_objects=$number_simplegateways

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# times
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=time
export APICLIobjectstype=times

objectstotal_times=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_times="$objectstotal_times"
export number_of_objects=$number_times

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# time_groups
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=time-group
export APICLIobjectstype=time-groups

objectstotal_time_groups=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_time_groups="$objectstotal_time_groups"
export number_of_objects=$number_time_groups

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# access-roles
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=access-role
export APICLIobjectstype=access-roles

objectstotal_access_roles=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_access_roles="$objectstotal_access_roles"
export number_of_objects=$number_access_roles

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# opsec-applications
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=opsec-application
export APICLIobjectstype=opsec-applications

objectstotal_opsec_applications=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_opsec_applications="$objectstotal_opsec_applications"
export number_of_objects=$number_opsec_applications

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# Services and Applications
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

echo
echo 'Services and Applications'
echo
echo >> $APICLIlogfilepath
echo 'Services and Applications' >> $APICLIlogfilepath
echo >> $APICLIlogfilepath

# -------------------------------------------------------------------------------------------------
# services-tcp objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-tcp
export APICLIobjectstype=services-tcp

objectstotal_services_tcp=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_tcp="$objectstotal_services_tcp"
export number_of_objects=$number_services_tcp

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# services-udp objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-udp
export APICLIobjectstype=services-udp

objectstotal_services_udp=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_udp="$objectstotal_services_udp"
export number_of_objects=$number_services_udp

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# services-icmp objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-icmp
export APICLIobjectstype=services-icmp

objectstotal_services_icmp=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_icmp="$objectstotal_services_icmp"
export number_of_objects=$number_services_icmp

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# services-icmp6 objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-icmp6
export APICLIobjectstype=services-icmp6

objectstotal_services_icmp6=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_icmp6="$objectstotal_services_icmp6"
export number_of_objects=$number_services_icmp6

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# services-sctp objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-sctp
export APICLIobjectstype=services-sctp

objectstotal_services_sctp=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_sctp="$objectstotal_services_sctp"
export number_of_objects=$number_services_sctp

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# services-other objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-other
export APICLIobjectstype=services-other

objectstotal_services_other=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_other="$objectstotal_services_other"
export number_of_objects=$number_services_other

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# services-dce-rpc objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-dce-rpc
export APICLIobjectstype=services-dce-rpc

objectstotal_services_dce_rpc=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_dce_rpc="$objectstotal_services_dce_rpc"
export number_of_objects=$number_services_dce_rpc

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# services-rpc objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-rpc
export APICLIobjectstype=services-rpc

objectstotal_services_rpc=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_services_rpc="$objectstotal_services_rpc"
export number_of_objects=$number_services_rpc

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# service-groups objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=service-group
export APICLIobjectstype=service-groups

objectstotal_service_groups=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_service_groups="$objectstotal_service_groups"
export number_of_objects=$number_service_groups

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# application-sites objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=application-sites
export APICLIobjectstype=application-sites

objectstotal_application_sites=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_application_sites="$objectstotal_application_sites"
export number_of_objects=$number_application_sites

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# application-site-categories objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=application-site-category
export APICLIobjectstype=application-site-categories

objectstotal_application_site_categories=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_application_site_categories="$objectstotal_application_site_categories"
export number_of_objects=$number_application_site_categories

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# application-site-groups objects
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=application-site-groups
export APICLIobjectstype=application-site-groups

objectstotal_application_site_groups=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_application_site_groups="$objectstotal_application_site_groups"
export number_of_objects=$number_application_site_groups

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# Identifying Data
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

echo
echo 'Identifying Data'
echo

# -------------------------------------------------------------------------------------------------
# tags
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=tags
export APICLIobjectstype=tags

objectstotal_tags=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" --format json -s $APICLIsessionfile | $JQ ".total")
export number_tags="$objectstotal_tags"
export number_of_objects=$number_tags

echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype
echo 'Number of '$APICLIobjecttype' Objects is = '$number_of_objects' '$APICLIobjectstype >> $APICLIlogfilepath


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# no more simple objects
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# handle complex objects
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# group members
# -------------------------------------------------------------------------------------------------

export APICLIobjecttype=group-member
export APICLIobjectstype=group-members

# -------------------------------------------------------------------------------------------------
# PopulateArrayOfGroupObjects proceedure
# -------------------------------------------------------------------------------------------------

#
# PopulateArrayOfGroupObjects generates an array of group objects for further processing.

PopulateArrayOfGroupObjects () {
    
    # MGMT_CLI_GROUPS_STRING is a string with multiple lines. Each line contains a name of a group members.
    # in this example the output of mgmt_cli is not sent to a file, instead it is passed to jq directly using a pipe.
    
    MGMT_CLI_GROUPS_STRING="`mgmt_cli show groups details-level "standard" limit $APICLIObjectLimit details-level "standard" -s $APICLIsessionfile --format json | $JQ ".objects[].name | @sh" -r`"
    
    # break the string into an array - each element of the array is a line in the original string
    # there are simpler ways, but this way allows the names to contain spaces. Gaia's bash version is 3.x so readarray is not available
    
    while read -r line; do
        ALLGROUPARR+=("$line")
        echo -n '.'
    done <<< "$MGMT_CLI_GROUPS_STRING"
    echo
    
    return 0
}


# -------------------------------------------------------------------------------------------------
# GetArrayOfGroupObjects proceedure
# -------------------------------------------------------------------------------------------------

#
# GetArrayOfGroupObjects generates an array of group objects for further processing.

GetArrayOfGroupObjects () {
    
    #
    # APICLICSVsortparms can change due to the nature of the object
    #

    #export APICLIobjecttype=group
    #export APICLIobjectstype=groups
    
    echo
    echo 'Generate array of groups'
    echo
    
    ALLGROUPARR=()

    export MgmtCLI_Base_OpParms="--format json -s $APICLIsessionfile"
    export MgmtCLI_IgnoreErr_OpParms="ignore-warnings true ignore-errors true --ignore-errors true"
    
    export MgmtCLI_Show_OpParms="details-level \"$APICLIdetaillvl\" $MgmtCLI_Base_OpParms"
    
    objectstotal=$(mgmt_cli show $APICLIobjectstype limit 1 offset 0 details-level "standard" $MgmtCLI_Base_OpParms | $JQ ".total")

    objectstoshow=$objectstotal

    echo "Processing $objectstoshow $APICLIobjectstype objects in $APICLIObjectLimit object chunks:"

    objectslefttoshow=$objectstoshow

    currentgroupoffset=0
    
    while [ $objectslefttoshow -ge 1 ] ; do
        # we have objects to process
        echo "  Now processing up to next $APICLIObjectLimit $APICLIobjecttype objects starting with object $currenthostoffset of $objectslefttoshow remaining!"

        PopulateArrayOfGroupObjects
        errorreturn=$?
        if [ $errorreturn != 0 ] ; then
            # Something went wrong, terminate
            exit $errorreturn
        fi

        objectslefttoshow=`expr $objectslefttoshow - $APICLIObjectLimit`
        currenthostoffset=`expr $currenthostoffset + $APICLIObjectLimit`
    done

    return 0
}


# -------------------------------------------------------------------------------------------------
# DumpArrayOfGroupObjects proceedure
# -------------------------------------------------------------------------------------------------

#
# DumpArrayOfGroupObjects outputs the array of group objects.

DumpArrayOfGroupObjects () {
    
    # print the elements in the array
    echo >> $APICLIlogfilepath
    echo Groups >> $APICLIlogfilepath
    echo >> $APICLIlogfilepath
    
    for i in "${ALLGROUPARR[@]}"
    do
        echo "$i, ${i//\'/}" >> $APICLIlogfilepath
    done
    
    return 0
}


# -------------------------------------------------------------------------------------------------
# CountMembersInGroupObjects proceedure
# -------------------------------------------------------------------------------------------------

#
# CountMembersInGroupObjects outputs the number of group members in a group in the array of group objects.

CountMembersInGroupObjects () {
        
        
    #
    # using bash variables in a jq expression
    #
    
    echo
    echo 'Use array of groups to count group members in each group'ls 
    echo
    echo >> $APICLIlogfilepath
    echo 'Use array of groups to count group members in each group' >> $APICLIlogfilepath
    echo >> $APICLIlogfilepath
    
    for i in "${ALLGROUPARR[@]}"
    do
    
        MEMBERS_COUNT=$(mgmt_cli show group name "${i//\'/}" -s $APICLIsessionfile --format json | $JQ ".members | length")
    
        echo Group "${i//\'/}"' number of members = '"$MEMBERS_COUNT"
        echo Group "${i//\'/}"' number of members = '"$MEMBERS_COUNT" >> $APICLIlogfilepath

    done
    
    return 0
}


# -------------------------------------------------------------------------------------------------

if [ $number_groups -le 0 ] ; then
    # No groups found
    echo
    echo 'No groups to generate members from!'
    echo
    echo >> $APICLIlogfilepath
    echo 'No groups to generate members from!' >> $APICLIlogfilepath
    echo >> $APICLIlogfilepath
else
    GetArrayOfGroupObjects
    DumpArrayOfGroupObjects
    CountMembersInGroupObjects
fi

# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------


# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------
# no more complex objects
# -------------------------------------------------------------------------------------------------
# -------------------------------------------------------------------------------------------------

# -------------------------------------------------------------------------------------------------
# no more objects
# -------------------------------------------------------------------------------------------------

echo
echo 'Dumps Completed!'
echo
echo >> $APICLIlogfilepath
echo 'Dumps Completed!' >> $APICLIlogfilepath
echo >> $APICLIlogfilepath


# =================================================================================================
# END:  Main operations - 
# =================================================================================================
# -------------------------------------------------------------------------------------------------
# =================================================================================================


# =================================================================================================
# =================================================================================================
# START:  Publish, Cleanup, and Dump output
# =================================================================================================


# MODIFIED 2017-07-21 \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

# -------------------------------------------------------------------------------------------------
# Publish Changes
# -------------------------------------------------------------------------------------------------


if [ x"$script_use_publish" = x"TRUE" ] ; then
    echo
    echo 'Publish changes!'
    echo
    mgmt_cli publish -s $APICLIsessionfile
    echo
else
    echo
    echo 'Nothing to Publish!'
    echo
fi

#
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ MODIFIED 2017-07-21

# -------------------------------------------------------------------------------------------------
# Logout from mgmt_cli, also cleanup session file
# -------------------------------------------------------------------------------------------------

echo
echo 'Logout of mgmt_cli!  Then remove session file.'
echo
mgmt_cli logout -s $APICLIsessionfile

rm $APICLIsessionfile

# MODIFIED 2017-07-21 \/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
#

# -------------------------------------------------------------------------------------------------
# Clean-up and exit
# -------------------------------------------------------------------------------------------------

echo 'CLI Operations Completed'

if [ "$APICLIlogpathbase" != "$APICLIpathroot" ] ; then
    echo
    ls -alh $APICLIlogpathbase
    echo
fi

echo
ls -alh $APICLIpathroot
echo
echo
ls -alhR $APICLIpathroot/$DATE
echo

echo "Log output in file $APICLIlogfilepath"
echo

#
# /\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\ MODIFIED 2017-07-21


# =================================================================================================
# END:  Publish, Cleanup, and Dump output
# =================================================================================================
# =================================================================================================


