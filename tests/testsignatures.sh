#!/bin/bash

set -e

if test "${MAINTESTOPTIONS+set}" != set ; then
	source $(dirname $0)/test.inc
	STANDALONE="true"
else
	STANDALONE=""
fi

rm -rf db dists pool lists conf gpgtestdir

mkdir -p gpgtestdir
export GNUPGHOME="`pwd`/gpgtestdir"
gpg --import $SRCDIR/tests/good.key $SRCDIR/tests/evil.key $SRCDIR/tests/expired.key $SRCDIR/tests/revoked.key

mkdir -p conf
cat > conf/options <<CONFEND
export changed
CONFEND
cat > conf/distributions <<CONFEND
Codename: ATest
Uploaders: auploaders
Architectures: ${FAKEARCHITECTURE} source
Components: everything

Codename: BTest
Uploaders: buploaders
Architectures: ${FAKEARCHITECTURE} source
Components: everything

Codename: CTest
Uploaders: cuploaders
Architectures: ${FAKEARCHITECTURE} source
Components: everything
CONFEND

gpg --list-keys

cat > conf/auploaders <<CONFEND
# Nothing is allowed in here
CONFEND
cat > conf/buploaders <<CONFEND
allow * by key FFFFFFFF
allow * by key DC3C29B8
allow * by key 685AF714
allow * by key 00000000
CONFEND
cat > conf/cuploaders <<CONFEND
allow * by key FFFFFFFF
allow * by any key
allow * by unsigned
allow * by key 00000000
allow * by anybody
CONFEND
cat > conf/incoming <<CONFEND
Name: abc
Incomingdir: i
TempDir: tmp
Allow: ATest BTest CTest

Name: ab
Incomingdir: i
TempDir: tmp
Allow: ATest BTest
CONFEND
mkdir i tmp

DISTRI="ATest BTest CTest" PACKAGE=package EPOCH="" VERSION=9 REVISION="-2" SECTION="otherofs" genpackage.sh
echo generating signature with evil key:
gpg --default-key evil@nowhere.tld --sign -a test.changes
mv test.changes.asc testbadsigned.changes
echo generating signature with good key:
gpg --default-key good@nowhere.tld --sign -a test.changes
mv test.changes.asc testsigned.changes
echo generating signature with revoked key:
gpg --expert --default-key revoked@nowhere.tld --sign -a test.changes
mv test.changes.asc testrevsigned.changes
gpg --import $SRCDIR/tests/revoked.pkey


testrun - -b . include ATest test.changes 3<<EOF
return 255
stderr
=Data seems not to be signed trying to use directly...
*=No rule allowing this package in found in auploaders!
*=To ignore use --ignore=uploaders.
-v0*=There have been errors!
stdout
-v2*=Created directory "./db"
stdout
EOF

testrun - -b . include BTest test.changes 3<<EOF
return 255
stderr
=Data seems not to be signed trying to use directly...
*=No rule allowing this package in found in buploaders!
*=To ignore use --ignore=uploaders.
-v0*=There have been errors!
stdout
EOF

testrun - -b . include CTest test.changes 3<<EOF
stderr
=Data seems not to be signed trying to use directly...
stdout
-v2*=Created directory "./pool"
-v2*=Created directory "./pool/everything"
-v2*=Created directory "./pool/everything/p"
-v2*=Created directory "./pool/everything/p/package"
-d1*=db: 'pool/everything/p/package/package-addons_9-2_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/everything/p/package/package_9-2_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/everything/p/package/package_9-2.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/everything/p/package/package_9-2.dsc' added to checksums.db(pool).
-d1*=db: 'package-addons' added to packages.db(CTest|everything|${FAKEARCHITECTURE}).
-d1*=db: 'package' added to packages.db(CTest|everything|${FAKEARCHITECTURE}).
-d1*=db: 'package' added to packages.db(CTest|everything|source).
-v0*=Exporting indices...
-v2*=Created directory "./dists"
-v2*=Created directory "./dists/CTest"
-v2*=Created directory "./dists/CTest/everything"
-v2*=Created directory "./dists/CTest/everything/binary-${FAKEARCHITECTURE}"
-v6*= looking for changes in 'CTest|everything|${FAKEARCHITECTURE}'...
-v6*=  creating './dists/CTest/everything/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped)
-v2*=Created directory "./dists/CTest/everything/source"
-v6*= looking for changes in 'CTest|everything|source'...
-v6*=  creating './dists/CTest/everything/source/Sources' (gzipped)
EOF

testrun - -b . include ATest testbadsigned.changes 3<<EOF
return 255
stderr
=Data seems not to be signed trying to use directly...
*=No rule allowing this package in found in auploaders!
*=To ignore use --ignore=uploaders.
-v0*=There have been errors!
stdout
EOF

testrun - -b . include BTest testbadsigned.changes 3<<EOF
return 255
stderr
=Data seems not to be signed trying to use directly...
*=No rule allowing this package in found in buploaders!
*=To ignore use --ignore=uploaders.
-v0*=There have been errors!
stdout
EOF

testrun - -b . include CTest testbadsigned.changes 3<<EOF
stderr
=Data seems not to be signed trying to use directly...
*=Skipping inclusion of 'package-addons' '9-2' in 'CTest|everything|${FAKEARCHITECTURE}', as it has already '9-2'.
*=Skipping inclusion of 'package' '9-2' in 'CTest|everything|${FAKEARCHITECTURE}', as it has already '9-2'.
*=Skipping inclusion of 'package' '9-2' in 'CTest|everything|source', as it has already '9-2'.
stdout
EOF

testrun - -b . include ATest testrevsigned.changes 3<<EOF
return 255
stderr
-v1*=Ignoring signature with '12D6C95C8C737389EAAF535972F1D61F685AF714' on 'testrevsigned.changes', as the key is revoked.
=Data seems not to be signed trying to use directly...
*=No rule allowing this package in found in auploaders!
*=To ignore use --ignore=uploaders.
-v0*=There have been errors!
stdout
EOF

testrun - -b . include BTest testrevsigned.changes 3<<EOF
return 255
stderr
-v1*=Ignoring signature with '12D6C95C8C737389EAAF535972F1D61F685AF714' on 'testrevsigned.changes', as the key is revoked.
=Data seems not to be signed trying to use directly...
*=No rule allowing this package in found in buploaders!
*=To ignore use --ignore=uploaders.
-v0*=There have been errors!
stdout
EOF

testrun - -b . include CTest testrevsigned.changes 3<<EOF
stderr
-v1*=Ignoring signature with '12D6C95C8C737389EAAF535972F1D61F685AF714' on 'testrevsigned.changes', as the key is revoked.
=Data seems not to be signed trying to use directly...
*=Skipping inclusion of 'package-addons' '9-2' in 'CTest|everything|${FAKEARCHITECTURE}', as it has already '9-2'.
*=Skipping inclusion of 'package' '9-2' in 'CTest|everything|${FAKEARCHITECTURE}', as it has already '9-2'.
*=Skipping inclusion of 'package' '9-2' in 'CTest|everything|source', as it has already '9-2'.
stdout
EOF

testrun - -b . include ATest testsigned.changes 3<<EOF
return 255
stderr
=Data seems not to be signed trying to use directly...
*=No rule allowing this package in found in auploaders!
*=To ignore use --ignore=uploaders.
-v0*=There have been errors!
stdout
EOF

testrun - -b . include BTest testsigned.changes 3<<EOF
stderr
=Data seems not to be signed trying to use directly...
stdout
-d1*=db: 'package-addons' added to packages.db(BTest|everything|${FAKEARCHITECTURE}).
-d1*=db: 'package' added to packages.db(BTest|everything|${FAKEARCHITECTURE}).
-d1*=db: 'package' added to packages.db(BTest|everything|source).
-v0*=Exporting indices...
-v2*=Created directory "./dists/BTest"
-v2*=Created directory "./dists/BTest/everything"
-v2*=Created directory "./dists/BTest/everything/binary-${FAKEARCHITECTURE}"
-v6*= looking for changes in 'BTest|everything|${FAKEARCHITECTURE}'...
-v6*=  creating './dists/BTest/everything/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped)
-v2*=Created directory "./dists/BTest/everything/source"
-v6*= looking for changes in 'BTest|everything|source'...
-v6*=  creating './dists/BTest/everything/source/Sources' (gzipped)
EOF

testrun - -b . include CTest testsigned.changes 3<<EOF
stderr
=Data seems not to be signed trying to use directly...
*=Skipping inclusion of 'package-addons' '9-2' in 'CTest|everything|${FAKEARCHITECTURE}', as it has already '9-2'.
*=Skipping inclusion of 'package' '9-2' in 'CTest|everything|${FAKEARCHITECTURE}', as it has already '9-2'.
*=Skipping inclusion of 'package' '9-2' in 'CTest|everything|source', as it has already '9-2'.
stdout
EOF

cp package* i/
cp test.changes i/
testrun - -b . processincoming ab 3<<EOF
return 243
stderr
=Data seems not to be signed trying to use directly...
*=No distribution accepting 'test.changes'!
-v0*=There have been errors!
stdout
EOF
testrun - -b . processincoming abc 3<<EOF
stderr
=Data seems not to be signed trying to use directly...
stdout
-v3*=Will not put 'package' in 'CTest|everything|source', as already there with same version '9-2'.
-v3*=Will not put 'package' in 'CTest|everything|${FAKEARCHITECTURE}', as already there with same version '9-2'.
-v3*=Will not put 'package-addons' in 'CTest|everything|${FAKEARCHITECTURE}', as already there with same version '9-2'.
-v0*=Skipping test.changes because all packages are skipped!
-v3*=deleting './i/package_9-2.dsc'...
-v3*=deleting './i/package-addons_9-2_all.deb'...
-v3*=deleting './i/package_9-2.tar.gz'...
-v3*=deleting './i/package_9-2_${FAKEARCHITECTURE}.deb'...
-v3*=deleting './i/test.changes'...
EOF

cp -i package* i/
cp testrevsigned.changes i/
testrun - -b . processincoming ab 3<<EOF
return 243
stderr
=Data seems not to be signed trying to use directly...
*=No distribution accepting 'testrevsigned.changes'!
-v0*=There have been errors!
-v1*=Ignoring signature with '12D6C95C8C737389EAAF535972F1D61F685AF714' on 'testrevsigned.changes', as the key is revoked.
#-v0*='testrevsigned.changes' would have been accepted into 'BTest' if signature with '12D6C95C8C737389EAAF535972F1D61F685AF714' was checkable and valid.
stdout
EOF
testrun - -b . processincoming abc 3<<EOF
stderr
=Data seems not to be signed trying to use directly...
-v1*=Ignoring signature with '12D6C95C8C737389EAAF535972F1D61F685AF714' on 'testrevsigned.changes', as the key is revoked.
#-v0*='testrevsigned.changes' would have been accepted into 'BTest' if signature with '12D6C95C8C737389EAAF535972F1D61F685AF714' was checkable and valid.
stdout
-v3*=Will not put 'package' in 'CTest|everything|source', as already there with same version '9-2'.
-v3*=Will not put 'package' in 'CTest|everything|${FAKEARCHITECTURE}', as already there with same version '9-2'.
-v3*=Will not put 'package-addons' in 'CTest|everything|${FAKEARCHITECTURE}', as already there with same version '9-2'.
-v0*=Skipping testrevsigned.changes because all packages are skipped!
-v3*=deleting './i/package_9-2.dsc'...
-v3*=deleting './i/package-addons_9-2_all.deb'...
-v3*=deleting './i/package_9-2.tar.gz'...
-v3*=deleting './i/package_9-2_${FAKEARCHITECTURE}.deb'...
-v3*=deleting './i/testrevsigned.changes'...
EOF

cp -i package* i/
cp testbadsigned.changes i/
testrun - -b . processincoming ab 3<<EOF
return 243
stderr
=Data seems not to be signed trying to use directly...
*=No distribution accepting 'testbadsigned.changes'!
-v0*=There have been errors!
stdout
EOF
testrun - -b . processincoming abc 3<<EOF
stderr
=Data seems not to be signed trying to use directly...
stdout
-v3*=Will not put 'package' in 'CTest|everything|source', as already there with same version '9-2'.
-v3*=Will not put 'package' in 'CTest|everything|${FAKEARCHITECTURE}', as already there with same version '9-2'.
-v3*=Will not put 'package-addons' in 'CTest|everything|${FAKEARCHITECTURE}', as already there with same version '9-2'.
-v0*=Skipping testbadsigned.changes because all packages are skipped!
-v3*=deleting './i/package_9-2.dsc'...
-v3*=deleting './i/package-addons_9-2_all.deb'...
-v3*=deleting './i/package_9-2.tar.gz'...
-v3*=deleting './i/package_9-2_${FAKEARCHITECTURE}.deb'...
-v3*=deleting './i/testbadsigned.changes'...
EOF

rm -rf db conf dists pool gpgtestdir i tmp
rm package-addons* package_* *.changes

if test x$STANDALONE = xtrue ; then
	set +v +x
	echo
	echo "If the script is still running to show this,"
	echo "all tested cases seem to work. (Though writing some tests more can never harm)."
fi
exit 0
