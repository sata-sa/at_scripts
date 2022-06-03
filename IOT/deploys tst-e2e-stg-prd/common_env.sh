#!/bin/bash

##MISC
check_file='/tmp/output_tst3'
###COLORS
GREEN="\E[0;32;1m"
BLUE="\E[0;34;1m"
RED="\E[0;31;1m"
YELLOW="\E[0;33;1m"
BBLACK="\E[40m"
BLINK="\E[5m"
RESET="\E[0m"
out_info()
{
  echo -e "[`date +%Y/%m/%d\ %H:%M:%S`] [${BLUE}${BBLACK} $* ${RESET}]"
}
out_ok()
{
  echo -e "[`date +%Y/%m/%d\ %H:%M:%S`] [${GREEN}${BBLACK} $* ${RESET}]"
}
out_warning()
{
  echo -e "[`date +%Y/%m/%d\ %H:%M:%S`] [${YELLOW}${BBLACK} $* ${RESET}]"
}
out_failure(){
  echo -e "[`date +%Y/%m/%d\ %H:%M:%S`] [${RED}${BBLACK} $* ${RESET}]"
}
