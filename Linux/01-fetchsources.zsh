#!/bin/zsh -f

setopt extendedglob
setopt err_exit

MYDIR="$(cd ${0:h} && pwd)"
SRCDIR=${MYDIR}/src

# git repositories for the sources in order of
# (project, URL, branch[:TagOrHash])
gitrepos=(
    diffpy.Structure
        https://github.com/diffpy/diffpy.Structure.git
        master
    diffpy.utils
        https://github.com/diffpy/diffpy.utils.git
        master
    pyobjcryst
        https://github.com/diffpy/pyobjcryst.git
        master
    periodictable
        https://github.com/pkienzle/periodictable.git
        master
    cxxtest
        https://github.com/CxxTest/cxxtest.git
        master
    libdiffpy
        https://github.com/diffpy/libdiffpy.git
        develop
    libobjcryst
        https://github.com/diffpy/libobjcryst.git
        master:v1.9.8b
    diffpy.srreal
        https://github.com/diffpy/diffpy.srreal.git
        develop
    diffpy.srfit
        https://github.com/diffpy/diffpy.srfit.git
        master
)

# Mercurial repositories for the sources in order of
# (project, URL, branch[:TagOrHash])
hgrepos=(
    pycifrw
        https://pavoljuhas@bitbucket.org/pavoljuhas/pycifrw
        stable
)

# URLs to source code bundles as (directory, URL)
tarballs=( )

# Subversion repositories as (targetpath, URL)
svnrepos=(
    sans/data_util
        svn://svn@danse.us/common/util
    sans/sansdataloader
        svn://svn@danse.us/sans/trunk/sansdataloader
    sans/sansmodels
        svn://svn@danse.us/sans/trunk/sansmodels
    sans/pr_inversion
        svn://svn@danse.us/sans/trunk/pr_inversion
)


fetchgitrepository() {
    [[ $# == 3 ]] || exit $?
    local tgtdir=$1 url=$2 branch=${3%%:*}
    local tag=${${3#${branch}}##*:}
    if [[ ! -d $tgtdir ]]; then
        git clone -b $branch $url $tgtdir
    else (
        cd $tgtdir &&
        git checkout $branch &&
        git pull --tags origin $branch
        )
    fi
    if [[ -n $tag ]]; then (
        cd $tgtdir
        if [[ -n "$(git branch --contains $tag $branch)" ]]; then
            git reset --hard $tag
        else
            git checkout --quiet $tag
        fi
        )
    fi
}


fetchhgrepository() {
    [[ $# == 3 ]] || exit $?
    local tgtdir=$1 url=$2 branch=${3%%:*}
    local tag=${${3#${branch}}##*:}
    if [[ ! -d $tgtdir ]]; then
        hg clone -b $branch $url $tgtdir
    else
        ( cd $tgtdir && hg pull -u -b $branch )
    fi
    if [[ -n $tag ]]; then
        ( cd $tgtdir && hg update $tag )
    fi
}


fetchsvnrepository() {
    [[ $# == 2 ]] || exit $?
    local tgtdir=$1 url=$2
    svn checkout $url $tgtdir
}


fetchtarball() {
    [[ $# == 2 ]] || exit $?
    local tgtdir=$1 url=$2
    local wget_opts
    wget_opts=( --timestamping --no-verbose )
    if [[ -d /opt/local/share/curl ]]; then
        wget_opts+=( --ca-directory=/opt/local/share/curl )
    fi
    mkdir -p $tgtdir
    ( cd $tgtdir && wget $wget_opts $url )
}


# Download all required sources
cd $SRCDIR
for t u b in $gitrepos;  fetchgitrepository $t $u $b
for t u b in $hgrepos;  fetchhgrepository $t $u $b
for t u in $svnrepos;  fetchsvnrepository $t $u
for t u in $tarballs;  fetchtarball $t $u