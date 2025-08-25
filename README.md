<!--

  Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
[![GitHub Contributors](https://dell-shield-io.cec.delllabs.net/github/contributors/vxrail/vxrail-api.svg?style=flat-square)](https://eos2git.cec.lab.emc.com/vxrail/vxrail-api/graphs/contributors)
[![GitHub stars](https://dell-shield-io.cec.delllabs.net/github/stars/vxrail/vxrail-api.svg?style=flat-square&label=github%20stars)](https://eos2git.cec.lab.emc.com/vxrail/vxrail-api)
[![Contribute](https://www.eclipse.org/che/contribute.svg)](https://devspaces.cec.delllabs.net/#https://eos2git.cec.lab.emc.com/vxrail/vxrail-api)
[![DRP checkers](https://eos2git.cec.lab.emc.com/vxrail/vxrail-api/actions/workflows/drp.yml/badge.svg)](https://eos2git.cec.lab.emc.com/vxrail/vxrail-api/actions/workflows/drp.yml)
[![Innersource Linters](https://eos2git.cec.lab.emc.com/vxrail/vxrail-api/actions/workflows/linters.yml/badge.svg)](https://eos2git.cec.lab.emc.com/vxrail/vxrail-api/actions/workflows/linters.yml)
[![Nexus](https://dell-shield-io.cec.delllabs.net/badge/powered_by-Nexus-blue)](https://isgdev.lab.dell.com/catalog/default/component/vxrail-api)

[![Copier](https://dell-shield-io.cec.delllabs.net/endpoint?url=https://raw.githubusercontent.com/copier-org/copier/master/img/badge/badge-grayscale-inverted-border-orange.json)](https://github.com/copier-org/copier)
 
  This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
  Use of this software and the intellectual property contained therein is expressly limited to the terms and 
  conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.
-->

# PowerShell Modules for Dell EMC VxRail
The PowerShell Modules for Dell EMC VxRail allow data center and IT administrators to based on Windows PowerShell to automate and orchestrate the configuration and management of Dell EMC VxRail.

The capabilities of PowerShell modules for Dell EMC VxRail are gathering system information and performing Layer 2 Node Expansion. These tasks can be executed by running command-line Shell written in PowerShell syntax. The modules are written so that all the operations are idempotent, therefore making multiple identical requests has the same effect as making a single request.

# Support
The PowerShell modules for VxRail are supported by Dell EMC open source community, but not product support agreements, and are provided under the terms of the license attached to the source code. Dell EMC does not provide support for any source code modifications. For any Ansible module issues, questions or feedback, join the [Dell EMC Automation community](https://www.dell.com/community/Automation/bd-p/Automation).

# Support Platforms
- Dell EMC VxRail

# Prerequisites
- Windows PowerShell 5.0 or later.

- Download the [PowerShell Modules](https://github.com/dell/powershell-vxrail/releases) for VxRail.

- Extract the module contents to the following directory: 

   - C:\\Program Files\\WindowsPowerShell\\Modules.

- Please refer to two manual guides in /VxRail_Pre-Installation_PowerShell_Script/ folder and import the module.

   - ESXi Pre-Install IP Address PowerShell Script.pdf

   - VxRail Manager Pre-Installation IP Address PowerShell Script.pdf

# Idempotency
The modules are written in such a way that all requests are idempotent and hence fault-tolerant. This means that the result of a successfully performed request is independent of the number of times it is executed.

# Running PowerShell modules for VxRail
- Get-SystemInfo -version V3

   - Get-SystemInfo - Server {VxM_ip} - Username {VxM-account} - Password {password} -Version V3
