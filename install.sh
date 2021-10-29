#!/usr/bin/env bash
#
# This script is an orchestrator to invoke all of the other scripts in the correct places.
#

cat <<EOM

-----------------------------------------------------------------------------------------

████████╗███████╗ ██████╗████████╗ ██████╗ ███╗   ██╗     █████╗ ██████╗  ██████╗██╗  ██╗
╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔═══██╗████╗  ██║    ██╔══██╗██╔══██╗██╔════╝██║  ██║
   ██║   █████╗  ██║        ██║   ██║   ██║██╔██╗ ██║    ███████║██████╔╝██║     ███████║
   ██║   ██╔══╝  ██║        ██║   ██║   ██║██║╚██╗██║    ██╔══██║██╔══██╗██║     ██╔══██║
   ██║   ███████╗╚██████╗   ██║   ╚██████╔╝██║ ╚████║    ██║  ██║██║  ██║╚██████╗██║  ██║
   ╚═╝   ╚══════╝ ╚═════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═══╝    ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝

-------------------------------  Let's do some installing  ------------------------------

EOM

cat <<EOM
Testing check marks in terminus-font used by arch iso
U+237B ⍻ NOT CHECK MARK
U+2611 ☑ BALLOT BOX WITH CHECK
U+2705 ✅ WHITE HEAVY CHECK MARK
U+2713 ✓ CHECK MARK
U+2714 ✔ HEAVY CHECK MARK
U+1F5F8 🗸 LIGHT CHECK MARK
U+1F5F9 🗹 BALLOT BOX WITH BOLD CHECK
EOM

# Load & export all configurations so that they are accessible by the subsequent scripts.
# This might not work as expected given all the chroot goodness..  May need to re-source inside
# scripts, or pass in as args.
set -a
source ./default.conf
set +a

./0-base.sh