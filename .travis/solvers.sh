#!/bin/bash -x
# Make sure we exit if there is a failure
set -e
: ${SOLVERS?"Solvers must be specified"}

SOLVER_LIST=$(echo "${SOLVERS}" | sed 's/:/ /')

for solver in ${SOLVER_LIST}; do
  echo "Getting solver ${solver}"
  case ${solver} in
  STP)
    echo "STP"
    mkdir stp
    cd stp
    ${KLEE_SRC}/.travis/stp.sh
    cd ../
    ;;
  Z3)
    # FIXME: Move this into its own script
    source ${KLEE_SRC}/.travis/sanitizer_flags.sh
    if [ "X${IS_SANITIZED_BUILD}" != "X0" ]; then
      echo "Error: Requested Sanitized build but Z3 being used is not sanitized"
      exit 1
    fi
    echo "Z3"
    # Should we install libz3-dbg too?
    # apt-get does not work. Build manually.
    #sudo apt-get -y install libz3 libz3-dev
    wget https://github.com/Z3Prover/z3/archive/refs/tags/z3-4.4.0.zip && unzip z3-4.4.0.zip && mv z3-z3-4.4.0 /tmp
    cd /tmp/z3-z3-4.4.0 && iconv -c -f utf-8 -t ascii src/api/dotnet/Properties/AssemblyInfo -o src/api/dotnet/Properties/AssemblyInfo
    # Remove things specific to x86 or causing build errors
    #RUN cd /tmp/z3-z3-4.4.0 && sed -i -e 's/-msse -msse2//g' -e 's/-mfpmath=sse//g' -e 's/-D_USE_THREAD_LOCAL//g' scripts/mk_util.py
    cd /tmp/z3-z3-4.4.0 && CXXFLAGS=-fPIC python scripts/mk_make.py && cd build && make -j && sudo make install
    ;;
  metaSMT)
    echo "metaSMT"
    ${KLEE_SRC}/.travis/metaSMT.sh
    ;;
  *)
    echo "Unknown solver ${solver}"
    exit 1
  esac
done
