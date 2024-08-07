# Copyright (c) 2015 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# This software contains the intellectual property of Dell Inc. or is licensed to Dell Inc. from third parties.
# Use of this software and the intellectual property contained therein is expressly limited to the terms and 
# conditions of the License Agreement under which it is provided by or on behalf of Dell Inc. or its subsidiaries.

import sys
import os
import time

def prepare_for_vxrail_smart_bundle_mounting_point():
    if not os.path.exists("/home/mystic/vxrail_smart_bundles"):
        sh_cmd = "mkdir -p /data/store2/vxrail_smart_bundles"
        ret = os.system(sh_cmd)
        time.sleep(1)

        sh_cmd = "chown mystic:root /data/store2/vxrail_smart_bundles"
        ret = os.system(sh_cmd)
        time.sleep(1)

        sh_cmd = "mkdir -p /home/mystic/vxrail_smart_bundles"
        ret = os.system(sh_cmd)
        time.sleep(1)

        sh_cmd = "chown mystic:root /home/mystic/vxrail_smart_bundles"
        ret = os.system(sh_cmd)
        time.sleep(1)

        sh_cmd = "mount --bind /data/store2/vxrail_smart_bundles /home/mystic/vxrail_smart_bundles"
        ret = os.system(sh_cmd)
        time.sleep(1)

        #clean up old record
        sh_cmd = "sed -i -e '/\/data\/store2\/vxrail_smart_bundles \/home\/mystic\/vxrail_smart_bundles none bind 0 0/d' \/etc\/fstab"
        ret = os.system(sh_cmd)
        #insert a mount point ensure it is unique
        sh_cmd = "sed -i '$a\\/data\/store2\/vxrail_smart_bundles \/home\/mystic\/vxrail_smart_bundles none bind 0 0' \/etc\/fstab"
        ret = os.system(sh_cmd)
        time.sleep(1)

prepare_for_vxrail_smart_bundle_mounting_point()
