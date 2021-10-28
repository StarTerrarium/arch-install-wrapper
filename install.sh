#!/usr/bin/env bash
#
# This script is an orchestrator to invoke all of the other scripts in the correct places.
#

cat << EOM

-----------------------------------------------------------------------------------------

████████╗███████╗ ██████╗████████╗ ██████╗ ███╗   ██╗     █████╗ ██████╗  ██████╗██╗  ██╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔═══██╗████╗  ██║    ██╔══██╗██╔══██╗██╔════╝██║  ██║
   ██║   █████╗  ██║        ██║   ██║   ██║██╔██╗ ██║    ███████║██████╔╝██║     ███████║
   ██║   ██╔══╝  ██║        ██║   ██║   ██║██║╚██╗██║    ██╔══██║██╔══██╗██║     ██╔══██║
   ██║   ███████╗╚██████╗   ██║   ╚██████╔╝██║ ╚████║    ██║  ██║██║  ██║╚██████╗██║  ██║
   ╚═╝   ╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═══╝    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

-------------------------------  Let's do some installing  ------------------------------

EOM

# Load & export all configurations so that they are accessible by the subsequent scripts.
# This might not work as expected given all the chroot goodness..  May need to re-source inside
# scripts, or pass in as args.
set -a
source ./customisation.conf
set +a

./0-base.sh