#!/usr/bin/env bash 
set -e 
set -o pipefail

ctr=$(buildah from fedora)
buildah config --author='Mauro S. M. Rodrigues <maurosr@linux.vnet.ibm.com>' $ctr
buildah run $ctr -- /bin/sh -c 'dnf install -y git gcc make automake iputils gdb net-tools; \
				git clone https://github.com/maurorodrigues/uperf.git; \
				mkdir -p /root/output/{stream,maerts,bidi,rr}'
buildah config --workingdir /uperf $ctr
buildah run $ctr -- /bin/sh -c './configure --enable-udp --enable-netstat --disable-sctp; \
				make; \
				make install'
buildah config --workingdir /root $ctr
buildah run $ctr -- /bin/sh -c 'rm -rf /uperf; \
				dnf remove -y git gcc make automake; \
				dnf clean all'

buildah add $ctr ./run.sh ./workload_profiles /root
buildah config --cmd="/root/run.sh" $ctr
buildah commit --rm $ctr maurosr/uperf
