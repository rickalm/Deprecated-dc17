# This is not shebang'ed since launching as a child makes no sense
# source this script so it runs in your process context
#

### code taken from https://github.com/jpetazzo/dind
###

# Close extraneous file descriptors.
#
pushd /proc/self/fd >/dev/null
for FD in *; do
	case "$FD" in
    # Keep stdin/stdout/stderr
    #
    [012])
      ;;
    # Nuke everything else
    #
    *)
      eval exec "$FD>&-"
      ;;
	esac
done
popd >/dev/null
