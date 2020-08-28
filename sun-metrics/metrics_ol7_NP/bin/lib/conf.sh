#!/bin/bash

# Current Scripts Directory
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
DIM_CONF=dims.conf
LOCAL_DIR=${SDIR}/../../local
DEFAULT_DIR=${SDIR}/../../default
LOCAL_DIMS=${LOCAL_DIR}/${DIM_CONF}
DEFAULT_DIMS=${DEFAULT_DIR}/${DIM_CONF}

load_all_dims() {
    cfg_parser ${DEFAULT_DIMS}
    cfg_section_all
    cfg_section_disk
}

load_local_dims() {
    if [[ -f ${LOCAL_DIMS} ]]; then
        cfg_parser ${LOCAL_DIMS}
        cfg_section_all
        cfg_section_disk
    fi

}

# Load ini parser
source ${SDIR}/parse_ini.sh

load_all_dims
load_local_dims
