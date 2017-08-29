# R8x-export-import-api-scripts
Check Point R8x Export, Import, [and more] API scripts for bash and powershell

CLI API Example for exporting, importing, and deleting different objects using CSV files (v00.25.00)

For a complete overview, review the PDF - TBD 


# Overview

The export, import, delete using CSV files scripts in this post, currently version 00.25.00, dated 2017-08-29, are intended to allow operations on an existing R80 or R80.10 Check Point management server (SMS or MDM) from bash on the management server or a management server able authenticate and reach the target management server.


These scripts show examples of:

- an export of objects and services with full and standard json output, and export of hosts, networks, groups, groups-with-exclusion, address-ranges, dns-domains, hosts interfaces, and group members to csv output [future services dump to csv is pending further research]
- an export of hosts, networks, groups, groups-with-exclusion, address-ranges, dns-domains, hosts interfaces, and group members to csv output [future services dump to csv is pending further research]
- an import of hosts, networks, groups, groups-with-exclusion, address-ranges, dns-domains, hosts interfaces, and group members from csv output generated by the export to csv operations above.
- a script to delete groups-with-exclusion, groups, address-ranges, dns-domains, networks, hosts, using csv files created by an object name export to csv for the respective items deleted.  NOTE:  DANGER!, DANGER!, DANGER!  Use at own risk with extreme care!

For immediate questions, hit me up at ericb(at)checkpoint.com

NOTE:  As of version 00.25.00 all cli_api*.sh scripts require "cmd_line_parameters_handler.action.common.001.sh" script to handle command line parameters!  Don't forget to copy this file also.

Description

This post includes a set of five (5) script packages, which can be used independently combined.  All script files end with .sh for shell and are intended for Check Point bash implementation on R80 and R80.10 or later.  Scripts in the packages have specific purposes and some scripts call sub-scripts for extensive repeated operations.  The packages also include specific expected default directory folders that are not created by the script action.

 

The packages are:

- Export Objects          :  cli_api_Export_Objects_v00.25.00_2017-08-29-0049CDT.7z
- Export Specific Objects :  cli_api_Export_Specific_Objects_v00.25.00_2017-08-29-0049CDT.7z
- Import Objects          :  cli_api_Import_Objects_v00.25.00_2017-08-29-0049CDT.7z
- Import Specific Objects :  cli_api_Import_Specific_Objects_v00.25.00_2017-08-29-0049CDT.7z
- Delete Objects          :  cli_api_Delete_Objects_v00.25.00_2017-08-29-0049CDT.7z
- template                :  template\api_mgmt_cli_shell_template_with_cmd_line_parameters.template.sh

 

