# R8x-export-import-api-scripts
Check Point R8x Export, Import, [and more] API scripts for bash and powershell

CLI API Example for exporting, importing, and deleting different objects using CSV files (v00.40.00)

For a complete overview, review the PDF - TBD 


# Overview

The export, import, set, and delete using CSV files scripts in this post, currently version 00.40.00 dated 2020-02-07, are intended to allow operations on an existing R80, R80.10, R80.20[.M?], R80.30, R80.40 Check Point management server (SMS or MDM) from bash on the management server or a management server (Check Point Gaia OS R8X) able to authenticate and reach the target management server.


These scripts show examples of:

- an export of objects and services with full and standard json output, and export of hosts, networks, groups, groups-with-exclusion, address-ranges, dns-domains, hosts interfaces, and group members to csv output [future services dump to csv is pending further research]
- an export of hosts, networks, groups, groups-with-exclusion, address-ranges, dns-domains, hosts interfaces, and group members to csv output [future services dump to csv is pending further research]
- an import of hosts, networks, groups, groups-with-exclusion, address-ranges, dns-domains, hosts interfaces, and group members from csv output generated by the export to csv operations above.
- a set of different objects, similar to the generic import operation, based on standard file names generated by export operation
- a script to delete groups-with-exclusion, groups, address-ranges, dns-domains, networks, hosts, using csv files created by an object name export to csv for the respective items deleted.  NOTE:  DANGER!, DANGER!, DANGER!  Use at own risk with extreme care!
- MDM script to document domains and output to a domains_list.txt file for reference in calls to other scripts
- Session Cleanup scripts to show and also remove zero lock sessions that may accumulate.

For direct questions, hit me up at ericb(at)checkpoint.com 
    or lookup information on https://community.checkpoint.com CheckMates community.

NOTE:  As of version 00.29.00 all cli_api*.sh scripts require "common" folder with script to handle command line parameters!  Don't forget to copy this folder also.

Description

This post includes a set of script packages, which can be used independently combined.  All script files end with .sh for shell and are intended for Check Point bash implementation on R80, R80.10, R80.20, R80.30, R80.40, or later.  Scripts in the packages have specific purposes and some scripts call sub-scripts for extensive repeated operations.  The packages also include specific expected default directory folders that are not created by the script action.  Template shell is also provided to generate other scripts.

The packages are:

- Export, Import, Set, Delete Object :  export_import.all.v00.40.00.tgz
- Common operations handlers         :  common.v00.40.00.tgz
- template for script development with command line parameter handling for the API from bash :  _templates.v00.40.00.tgz
- session cleanup handlers           :  Session_Cleanup.v03.00.00.template.v00.40.00.tgz

 
The approach to provided compressed packages was changed to facilitate quicker implementation on the management hosts.

Development folder contains the .wip versions of work in progress folders and may be updated directly for access to WORK-IN-PROGRESS (WIP) versions.  WIP versions are also provided with dedicated branches.

Operations folder contains the scripts as implemented by the author on the target management hosts


