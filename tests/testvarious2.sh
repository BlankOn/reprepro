#!/bin/bash

set -e
if [ "x$TESTINCSETUP" != "xissetup" ] ; then
        source $(dirname $0)/test.inc
fi

echo "Running various other old test..."
mkdir -p conf logs
cat > conf/options <<CONFEND
export changed
CONFEND
cat > conf/distributions <<CONFEND
Codename: test1
Architectures: ${FAKEARCHITECTURE} source
Components: stupid ugly
Update: Test2toTest1
DebIndices: Packages Release . .gz .bz2
UDebIndices: Packages .gz .bz2
DscIndices: Sources Release .gz .bz2
Tracking: keep includechanges includebyhand
Log: log1

Codename: test2
Architectures: ${FAKEARCHITECTURE} coal source
Components: stupid ugly
Origin: Brain
Label: Only a test
Suite: broken
Version: 9999999.02
DebIndices: Packages Release . .gz $SRCDIR/docs/bzip.example testhook
UDebIndices: Packages .gz
DscIndices: Sources Release . .gz $SRCDIR/docs/bzip.example testhook
Description: test with all fields set
DebOverride: binoverride
DscOverride: srcoverride
Log: log2
CONFEND

cat > conf/testhook <<'EOF'
#!/bin/sh
echo "testhook got $#: '$1' '$2' '$3' '$4'"
if test -f "$1/$3.deprecated" ; then
	echo "$3.deprecated.tobedeleted" >&3
fi
echo "super-compressed" > "$1/$3.super.new"
echo "$3.super.new" >&3
EOF
chmod a+x conf/testhook

mkdir -p "dists/test2/stupid/binary-${FAKEARCHITECTURE}"
touch "dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.deprecated"

set -v
checknolog logfile
testrun - -b . export test1 test2 3<<EOF
stdout
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'new'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'new'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'new'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'new'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'new'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'new'
-v2*=Created directory "./db"
-v1*=Exporting test2...
-v6*= exporting 'test2|stupid|${FAKEARCHITECTURE}'...
-v6*=  creating './dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v11*=Exporthook successfully returned!
-v2*=Created directory "./dists/test2/stupid/binary-coal"
-v6*= exporting 'test2|stupid|coal'...
-v6*=  creating './dists/test2/stupid/binary-coal/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v2*=Created directory "./dists/test2/stupid/source"
-v6*= exporting 'test2|stupid|source'...
-v6*=  creating './dists/test2/stupid/source/Sources' (uncompressed,gzipped,script: bzip.example,testhook)
-v2*=Created directory "./dists/test2/ugly"
-v2*=Created directory "./dists/test2/ugly/binary-${FAKEARCHITECTURE}"
-v6*= exporting 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*=  creating './dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v2*=Created directory "./dists/test2/ugly/binary-coal"
-v6*= exporting 'test2|ugly|coal'...
-v6*=  creating './dists/test2/ugly/binary-coal/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v2*=Created directory "./dists/test2/ugly/source"
-v6*= exporting 'test2|ugly|source'...
-v6*=  creating './dists/test2/ugly/source/Sources' (uncompressed,gzipped,script: bzip.example,testhook)
-v1*=Exporting test1...
-v2*=Created directory "./dists/test1"
-v2*=Created directory "./dists/test1/stupid"
-v2*=Created directory "./dists/test1/stupid/binary-${FAKEARCHITECTURE}"
-v6*= exporting 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  creating './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v2*=Created directory "./dists/test1/stupid/source"
-v6*= exporting 'test1|stupid|source'...
-v6*=  creating './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v2*=Created directory "./dists/test1/ugly"
-v2*=Created directory "./dists/test1/ugly/binary-${FAKEARCHITECTURE}"
-v6*= exporting 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  creating './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v2*=Created directory "./dists/test1/ugly/source"
-v6*= exporting 'test1|ugly|source'...
-v6*=  creating './dists/test1/ugly/source/Sources' (gzipped,bzip2ed)
EOF
dodo test '!' -e "dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.deprecated"
test -f dists/test1/Release
test -f dists/test2/Release

cat > dists/test1/stupid/binary-${FAKEARCHITECTURE}/Release.expected <<END
Component: stupid
Architecture: ${FAKEARCHITECTURE}
END
dodiff dists/test1/stupid/binary-${FAKEARCHITECTURE}/Release.expected dists/test1/stupid/binary-${FAKEARCHITECTURE}/Release
cat > dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release.expected <<END
Component: ugly
Architecture: ${FAKEARCHITECTURE}
END
echo "super-compressed" > "fakesuper"
FAKESUPERMD5="$(mdandsize fakesuper)"
FAKESUPERSHA1="$(sha1andsize fakesuper)"
FAKESUPERSHA2="$(sha2andsize fakesuper)"

dodiff dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release.expected dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release
cat > dists/test1/Release.expected <<END
Codename: test1
Date: normalized
Architectures: ${FAKEARCHITECTURE}
Components: stupid ugly
MD5Sum:
 $EMPTYMD5 stupid/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZMD5 stupid/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2MD5 stupid/binary-${FAKEARCHITECTURE}/Packages.bz2
 $(mdandsize dists/test1/stupid/binary-${FAKEARCHITECTURE}/Release) stupid/binary-${FAKEARCHITECTURE}/Release
 $EMPTYMD5 stupid/source/Sources
 $EMPTYGZMD5 stupid/source/Sources.gz
 $EMPTYBZ2MD5 stupid/source/Sources.bz2
 e38c7da133734e1fd68a7e344b94fe96 39 stupid/source/Release
 $EMPTYMD5 ugly/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZMD5 ugly/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2MD5 ugly/binary-${FAKEARCHITECTURE}/Packages.bz2
 $(mdandsize dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release) ugly/binary-${FAKEARCHITECTURE}/Release
 $EMPTYMD5 ugly/source/Sources
 $EMPTYGZMD5 ugly/source/Sources.gz
 $EMPTYBZ2MD5 ugly/source/Sources.bz2
 ed4ee9aa5d080f67926816133872fd02 37 ugly/source/Release
SHA1:
 $(sha1andsize dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages) stupid/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA1 stupid/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA1 stupid/binary-${FAKEARCHITECTURE}/Packages.bz2
 $(sha1andsize dists/test1/stupid/binary-${FAKEARCHITECTURE}/Release) stupid/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA1 stupid/source/Sources
 $EMPTYGZSHA1 stupid/source/Sources.gz
 $EMPTYBZ2SHA1 stupid/source/Sources.bz2
 ff71705a4cadaec55de5a6ebbfcd726caf2e2606 39 stupid/source/Release
 $EMPTYSHA1 ugly/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA1 ugly/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA1 ugly/binary-${FAKEARCHITECTURE}/Packages.bz2
 $(sha1andsize dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release) ugly/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA1 ugly/source/Sources
 $EMPTYGZSHA1 ugly/source/Sources.gz
 $EMPTYBZ2SHA1 ugly/source/Sources.bz2
 b297876e9d6ee3ee6083160003755047ede22a96 37 ugly/source/Release
SHA256:
 $(sha2andsize dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages) stupid/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA2 stupid/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA2 stupid/binary-${FAKEARCHITECTURE}/Packages.bz2
 $(sha2andsize dists/test1/stupid/binary-${FAKEARCHITECTURE}/Release) stupid/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA2 stupid/source/Sources
 $EMPTYGZSHA2 stupid/source/Sources.gz
 $EMPTYBZ2SHA2 stupid/source/Sources.bz2
 b88352d8e0227a133e2236c3a8961581562ee285980fc20bb79626d0d208aa51 39 stupid/source/Release
 $EMPTYSHA2 ugly/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA2 ugly/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA2 ugly/binary-${FAKEARCHITECTURE}/Packages.bz2
 $(sha2andsize dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release) ugly/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA2 ugly/source/Sources
 $EMPTYGZSHA2 ugly/source/Sources.gz
 $EMPTYBZ2SHA2 ugly/source/Sources.bz2
 edb5450a3f98a140b938c8266b8b998ba8f426c80ac733fe46423665d5770d9f 37 ugly/source/Release
END
cat > dists/test2/stupid/binary-${FAKEARCHITECTURE}/Release.expected <<END
Archive: broken
Version: 9999999.02
Component: stupid
Origin: Brain
Label: Only a test
Architecture: ${FAKEARCHITECTURE}
Description: test with all fields set
END
dodiff dists/test2/stupid/binary-${FAKEARCHITECTURE}/Release.expected dists/test2/stupid/binary-${FAKEARCHITECTURE}/Release
cat > dists/test2/ugly/binary-${FAKEARCHITECTURE}/Release.expected <<END
Archive: broken
Version: 9999999.02
Component: ugly
Origin: Brain
Label: Only a test
Architecture: ${FAKEARCHITECTURE}
Description: test with all fields set
END
dodiff dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release.expected dists/test1/ugly/binary-${FAKEARCHITECTURE}/Release
cat > dists/test2/Release.expected <<END
Origin: Brain
Label: Only a test
Suite: broken
Codename: test2
Version: 9999999.02
Date: normalized
Architectures: ${FAKEARCHITECTURE} coal
Components: stupid ugly
Description: test with all fields set
MD5Sum:
 $EMPTYMD5 stupid/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZMD5 stupid/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2MD5 stupid/binary-${FAKEARCHITECTURE}/Packages.bz2
 $FAKESUPERMD5 stupid/binary-${FAKEARCHITECTURE}/Packages.super
 $(mdandsize dists/test2/stupid/binary-${FAKEARCHITECTURE}/Release) stupid/binary-${FAKEARCHITECTURE}/Release
 $EMPTYMD5 stupid/binary-coal/Packages
 $EMPTYGZMD5 stupid/binary-coal/Packages.gz
 $EMPTYBZ2MD5 stupid/binary-coal/Packages.bz2
 $FAKESUPERMD5 stupid/binary-coal/Packages.super
 10ae2f283e1abdd3facfac6ed664035d 144 stupid/binary-coal/Release
 $EMPTYMD5 stupid/source/Sources
 $EMPTYGZMD5 stupid/source/Sources.gz
 $EMPTYBZ2MD5 stupid/source/Sources.bz2
 $FAKESUPERMD5 stupid/source/Sources.super
 b923b3eb1141e41f0b8bb74297ac8a36 146 stupid/source/Release
 $EMPTYMD5 ugly/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZMD5 ugly/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2MD5 ugly/binary-${FAKEARCHITECTURE}/Packages.bz2
 $FAKESUPERMD5 ugly/binary-${FAKEARCHITECTURE}/Packages.super
 $(mdandsize dists/test2/ugly/binary-${FAKEARCHITECTURE}/Release) ugly/binary-${FAKEARCHITECTURE}/Release
 $EMPTYMD5 ugly/binary-coal/Packages
 $EMPTYGZMD5 ugly/binary-coal/Packages.gz
 $EMPTYBZ2MD5 ugly/binary-coal/Packages.bz2
 $FAKESUPERMD5 ugly/binary-coal/Packages.super
 7a05de3b706d08ed06779d0ec2e234e9 142 ugly/binary-coal/Release
 $EMPTYMD5 ugly/source/Sources
 $EMPTYGZMD5 ugly/source/Sources.gz
 $EMPTYBZ2MD5 ugly/source/Sources.bz2
 $FAKESUPERMD5 ugly/source/Sources.super
 e73a8a85315766763a41ad4dc6744bf5 144 ugly/source/Release
SHA1:
 $EMPTYSHA1 stupid/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA1 stupid/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA1 stupid/binary-${FAKEARCHITECTURE}/Packages.bz2
 $FAKESUPERSHA1 stupid/binary-${FAKEARCHITECTURE}/Packages.super
 $(sha1andsize dists/test2/stupid/binary-${FAKEARCHITECTURE}/Release) stupid/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA1 stupid/binary-coal/Packages
 $EMPTYGZSHA1 stupid/binary-coal/Packages.gz
 $EMPTYBZ2SHA1 stupid/binary-coal/Packages.bz2
 $FAKESUPERSHA1 stupid/binary-coal/Packages.super
 $(sha1andsize dists/test2/stupid/binary-coal/Release) stupid/binary-coal/Release
 $EMPTYSHA1 stupid/source/Sources
 $EMPTYGZSHA1 stupid/source/Sources.gz
 $EMPTYBZ2SHA1 stupid/source/Sources.bz2
 $FAKESUPERSHA1 stupid/source/Sources.super
 $(sha1andsize dists/test2/stupid/source/Release) stupid/source/Release
 $EMPTYSHA1 ugly/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA1 ugly/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA1 ugly/binary-${FAKEARCHITECTURE}/Packages.bz2
 $FAKESUPERSHA1 ugly/binary-${FAKEARCHITECTURE}/Packages.super
 $(sha1andsize dists/test2/ugly/binary-${FAKEARCHITECTURE}/Release) ugly/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA1 ugly/binary-coal/Packages
 $EMPTYGZSHA1 ugly/binary-coal/Packages.gz
 $EMPTYBZ2SHA1 ugly/binary-coal/Packages.bz2
 $FAKESUPERSHA1 ugly/binary-coal/Packages.super
 $(sha1andsize dists/test2/ugly/binary-coal/Release) ugly/binary-coal/Release
 $EMPTYSHA1 ugly/source/Sources
 $EMPTYGZSHA1 ugly/source/Sources.gz
 $EMPTYBZ2SHA1 ugly/source/Sources.bz2
 $FAKESUPERSHA1 ugly/source/Sources.super
 $(sha1andsize dists/test2/ugly/source/Release) ugly/source/Release
SHA256:
 $EMPTYSHA2 stupid/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA2 stupid/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA2 stupid/binary-${FAKEARCHITECTURE}/Packages.bz2
 $FAKESUPERSHA2 stupid/binary-${FAKEARCHITECTURE}/Packages.super
 $(sha2andsize dists/test2/stupid/binary-${FAKEARCHITECTURE}/Release) stupid/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA2 stupid/binary-coal/Packages
 $EMPTYGZSHA2 stupid/binary-coal/Packages.gz
 $EMPTYBZ2SHA2 stupid/binary-coal/Packages.bz2
 $FAKESUPERSHA2 stupid/binary-coal/Packages.super
 $(sha2andsize dists/test2/stupid/binary-coal/Release) stupid/binary-coal/Release
 $EMPTYSHA2 stupid/source/Sources
 $EMPTYGZSHA2 stupid/source/Sources.gz
 $EMPTYBZ2SHA2 stupid/source/Sources.bz2
 $FAKESUPERSHA2 stupid/source/Sources.super
 $(sha2andsize dists/test2/stupid/source/Release) stupid/source/Release
 $EMPTYSHA2 ugly/binary-${FAKEARCHITECTURE}/Packages
 $EMPTYGZSHA2 ugly/binary-${FAKEARCHITECTURE}/Packages.gz
 $EMPTYBZ2SHA2 ugly/binary-${FAKEARCHITECTURE}/Packages.bz2
 $FAKESUPERSHA2 ugly/binary-${FAKEARCHITECTURE}/Packages.super
 $(sha2andsize dists/test2/ugly/binary-${FAKEARCHITECTURE}/Release) ugly/binary-${FAKEARCHITECTURE}/Release
 $EMPTYSHA2 ugly/binary-coal/Packages
 $EMPTYGZSHA2 ugly/binary-coal/Packages.gz
 $EMPTYBZ2SHA2 ugly/binary-coal/Packages.bz2
 $FAKESUPERSHA2 ugly/binary-coal/Packages.super
 $(sha2andsize dists/test2/ugly/binary-coal/Release) ugly/binary-coal/Release
 $EMPTYSHA2 ugly/source/Sources
 $EMPTYGZSHA2 ugly/source/Sources.gz
 $EMPTYBZ2SHA2 ugly/source/Sources.bz2
 $FAKESUPERSHA2 ugly/source/Sources.super
 $(sha2andsize dists/test2/ugly/source/Release) ugly/source/Release
END
printf '%%g/^Date:/s/Date: .*/Date: normalized/\n%%g/gz$/s/^ 163be0a88c70ca629fd516dbaadad96a / 7029066c27ac6f5ef18d660d5741979a /\nw\nq\n' | ed -s dists/test1/Release
printf '%%g/^Date:/s/Date: .*/Date: normalized/\n%%g/gz$/s/^ 163be0a88c70ca629fd516dbaadad96a / 7029066c27ac6f5ef18d660d5741979a /\nw\nq\n' | ed -s dists/test2/Release
dodiff dists/test1/Release.expected dists/test1/Release || exit 1
dodiff dists/test2/Release.expected dists/test2/Release || exit 1

PACKAGE=simple EPOCH="" VERSION=1 REVISION="" SECTION="stupid/base" genpackage.sh
checknolog log1
testrun - -b . include test1 test.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
stdout
-v2*=Created directory "./pool"
-v2*=Created directory "./pool/stupid"
-v2*=Created directory "./pool/stupid/s"
-v2*=Created directory "./pool/stupid/s/simple"
-d1*=db: 'pool/stupid/s/simple/simple-addons_1_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/s/simple/simple_1.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/s/simple/simple_1.dsc' added to checksums.db(pool).
-d1*=db: 'pool/stupid/s/simple/simple_1_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: 'simple-addons' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'simple' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'simple' added to packages.db(test1|stupid|source).
-d1*=db: 'simple' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
echo returned: $?
checklog log1 << EOF
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} simple-addons 1
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} simple 1
DATESTR add test1 dsc stupid source simple 1
EOF

PACKAGE=bloat+-0a9z.app EPOCH=99: VERSION=0.9-A:Z+a:z REVISION=-0+aA.9zZ SECTION="ugly/base" genpackage.sh
testrun - -b . include test1 test.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
stdout
-v2*=Created directory "./pool/ugly"
-v2*=Created directory "./pool/ugly/b"
-v2*=Created directory "./pool/ugly/b/bloat+-0a9z.app"
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: 'bloat+-0a9z.app-addons' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|ugly|source).
-d1*=db: 'bloat+-0a9z.app' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|source'...
-v6*=  replacing './dists/test1/ugly/source/Sources' (gzipped,bzip2ed)
EOF
echo returned: $?
checklog log1 <<EOF
DATESTR add test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app-addons 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR add test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR add test1 dsc ugly source bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
EOF

testrun - -b . -Tdsc remove test1 simple 3<<EOF
stdout
-v1*=removing 'simple' from 'test1|stupid|source'...
-d1*=db: 'simple' removed from packages.db(test1|stupid|source).
=[tracking_get test1 simple 1]
=[tracking_get found test1 simple 1]
=[tracking_save test1 simple 1]
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR remove test1 dsc stupid source simple 1
EOF
testrun - -b . -Tdeb remove test1 bloat+-0a9z.app 3<<EOF
stdout
-v1*=removing 'bloat+-0a9z.app' from 'test1|ugly|${FAKEARCHITECTURE}'...
-d1*=db: 'bloat+-0a9z.app' removed from packages.db(test1|ugly|${FAKEARCHITECTURE}).
=[tracking_get test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
=[tracking_get found test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
=[tracking_save test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR remove test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
testrun - -b . -A source remove test1 bloat+-0a9z.app 3<<EOF
stdout
-v1*=removing 'bloat+-0a9z.app' from 'test1|ugly|source'...
-d1*=db: 'bloat+-0a9z.app' removed from packages.db(test1|ugly|source).
=[tracking_get test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
=[tracking_get found test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
=[tracking_save test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
-v6*=  replacing './dists/test1/ugly/source/Sources' (gzipped,bzip2ed)
EOF
checklog log1 <<EOF
DATESTR remove test1 dsc ugly source bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
testrun - -b . -A ${FAKEARCHITECTURE} remove test1 simple 3<<EOF
stdout
-v1*=removing 'simple' from 'test1|stupid|${FAKEARCHITECTURE}'...
-d1*=db: 'simple' removed from packages.db(test1|stupid|${FAKEARCHITECTURE}).
=[tracking_get test1 simple 1]
=[tracking_get found test1 simple 1]
=[tracking_save test1 simple 1]
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR remove test1 deb stupid ${FAKEARCHITECTURE} simple 1
EOF
testrun - -b . -C ugly remove test1 bloat+-0a9z.app-addons 3<<EOF
stdout
-v1*=removing 'bloat+-0a9z.app-addons' from 'test1|ugly|${FAKEARCHITECTURE}'...
-d1*=db: 'bloat+-0a9z.app-addons' removed from packages.db(test1|ugly|${FAKEARCHITECTURE}).
=[tracking_get test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
=[tracking_get found test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
=[tracking_save test1 bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ]
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR remove test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app-addons 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
testrun - -b . -C stupid remove test1 simple-addons 3<<EOF
stdout
-v1*=removing 'simple-addons' from 'test1|stupid|${FAKEARCHITECTURE}'...
-d1*=db: 'simple-addons' removed from packages.db(test1|stupid|${FAKEARCHITECTURE}).
=[tracking_get test1 simple 1]
=[tracking_get found test1 simple 1]
=[tracking_save test1 simple 1]
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR remove test1 deb stupid ${FAKEARCHITECTURE} simple-addons 1
EOF
CURDATE="`TZ=GMT LC_ALL=C date +'%a, %d %b %Y %H:%M:%S UTC'`"
printf '%%g/^Date:/s/Date: .*/Date: normalized/\n%%g/gz$/s/^ 163be0a88c70ca629fd516dbaadad96a / 7029066c27ac6f5ef18d660d5741979a /\nw\nq\n' | ed -s dists/test1/Release

dodiff dists/test1/Release.expected dists/test1/Release || exit 1

cat > conf/srcoverride <<END
simple Section ugly/games
simple Priority optional
simple Maintainer simple.source.maintainer
bloat+-0a9z.app Section stupid/X11
bloat+-0a9z.app Priority optional
bloat+-0a9z.app X-addition totally-unsupported
bloat+-0a9z.app Maintainer bloat.source.maintainer
END
cat > conf/binoverride <<END
simple Maintainer simple.maintainer
simple Section ugly/base
simple Priority optional
simple-addons Section ugly/addons
simple-addons Priority optional
simple-addons Maintainer simple.add.maintainer
bloat+-0a9z.app Maintainer bloat.maintainer
bloat+-0a9z.app Section stupid/base
bloat+-0a9z.app Priority optional
bloat+-0a9z.app-addons Section stupid/addons
bloat+-0a9z.app-addons Maintainer bloat.add.maintainer
bloat+-0a9z.app-addons Priority optional
END

testrun - -b . -Tdsc -A source includedsc test2 simple_1.dsc 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
-v1=simple_1.dsc: component guessed as 'ugly'
stdout
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'change'
-v2*=Created directory "./pool/ugly/s"
-v2*=Created directory "./pool/ugly/s/simple"
-d1*=db: 'pool/ugly/s/simple/simple_1.dsc' added to checksums.db(pool).
-d1*=db: 'pool/ugly/s/simple/simple_1.tar.gz' added to checksums.db(pool).
-d1*=db: 'simple' added to packages.db(test2|ugly|source).
-v0*=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v11*=Exporthook successfully returned!
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
-v6*=  replacing './dists/test2/ugly/source/Sources' (uncompressed,gzipped,script: bzip.example,testhook)
EOF
checklog log2 <<EOF
DATESTR add test2 dsc ugly source simple 1
EOF
testrun - -b . -Tdsc -A source includedsc test2 bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
-v1=bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc: component guessed as 'stupid'
stdout
-v2*=Created directory "./pool/stupid/b"
-v2*=Created directory "./pool/stupid/b/bloat+-0a9z.app"
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc' added to checksums.db(pool).
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz' added to checksums.db(pool).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test2|stupid|source).
-v0*=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v11*=Exporthook successfully returned!
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*=  replacing './dists/test2/stupid/source/Sources' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'change'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'old'
EOF
checklog log2 <<EOF
DATESTR add test2 dsc stupid source bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
testrun - -b . -Tdeb -A ${FAKEARCHITECTURE} includedeb test2 simple_1_${FAKEARCHITECTURE}.deb 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
-v1=simple_1_${FAKEARCHITECTURE}.deb: component guessed as 'ugly'
stdout
-d1*=db: 'pool/ugly/s/simple/simple_1_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'simple' added to packages.db(test2|ugly|${FAKEARCHITECTURE}).
-v0*=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v11*=Exporthook successfully returned!
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'change'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'old'
EOF
checklog log2  <<EOF
DATESTR add test2 deb ugly ${FAKEARCHITECTURE} simple 1
EOF
testrun - -b . -Tdeb -A coal includedeb test2 simple-addons_1_all.deb 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
-v1=simple-addons_1_all.deb: component guessed as 'ugly'
stdout
-d1*=db: 'pool/ugly/s/simple/simple-addons_1_all.deb' added to checksums.db(pool).
-d1*=db: 'simple-addons' added to packages.db(test2|ugly|coal).
-v0=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v11*=Exporthook successfully returned!
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*=  replacing './dists/test2/ugly/binary-coal/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|ugly|source'...
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'change'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'old'
EOF
checklog log2  <<EOF
DATESTR add test2 deb ugly coal simple-addons 1
EOF
testrun - -b . -Tdeb -A ${FAKEARCHITECTURE} includedeb test2 bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
-v1=bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb: component guessed as 'stupid'
stdout
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test2|stupid|${FAKEARCHITECTURE}).
-v0=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v11*=Exporthook successfully returned!
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'change'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'old'
EOF
checklog log2 <<EOF
DATESTR add test2 deb stupid ${FAKEARCHITECTURE} bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
testrun - -b . -Tdeb -A coal includedeb test2 bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
-v1=bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb: component guessed as 'stupid'
stdout
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb' added to checksums.db(pool).
-d1*=db: 'bloat+-0a9z.app-addons' added to packages.db(test2|stupid|coal).
-v0=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v11*=Exporthook successfully returned!
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*=  replacing './dists/test2/stupid/binary-coal/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|stupid|source'...
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'change'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'old'
EOF
checklog log2 <<EOF
DATESTR add test2 deb stupid coal bloat+-0a9z.app-addons 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
find dists/test2/ \( -name "Packages.gz" -o -name "Sources.gz" \) -print0 | xargs -0 zgrep '^\(Package\|Maintainer\|Section\|Priority\): ' | sort > results
cat >results.expected <<END
dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.gz:Maintainer: bloat.maintainer
dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.gz:Package: bloat+-0a9z.app
dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.gz:Priority: optional
dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.gz:Section: stupid/base
dists/test2/stupid/binary-coal/Packages.gz:Maintainer: bloat.add.maintainer
dists/test2/stupid/binary-coal/Packages.gz:Package: bloat+-0a9z.app-addons
dists/test2/stupid/binary-coal/Packages.gz:Priority: optional
dists/test2/stupid/binary-coal/Packages.gz:Section: stupid/addons
dists/test2/stupid/source/Sources.gz:Maintainer: bloat.source.maintainer
dists/test2/stupid/source/Sources.gz:Package: bloat+-0a9z.app
dists/test2/stupid/source/Sources.gz:Priority: optional
dists/test2/stupid/source/Sources.gz:Section: stupid/X11
dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages.gz:Maintainer: simple.maintainer
dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages.gz:Package: simple
dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages.gz:Priority: optional
dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages.gz:Section: ugly/base
dists/test2/ugly/binary-coal/Packages.gz:Maintainer: simple.add.maintainer
dists/test2/ugly/binary-coal/Packages.gz:Package: simple-addons
dists/test2/ugly/binary-coal/Packages.gz:Priority: optional
dists/test2/ugly/binary-coal/Packages.gz:Section: ugly/addons
dists/test2/ugly/source/Sources.gz:Maintainer: simple.source.maintainer
dists/test2/ugly/source/Sources.gz:Package: simple
dists/test2/ugly/source/Sources.gz:Priority: optional
dists/test2/ugly/source/Sources.gz:Section: ugly/games
END
dodiff results.expected results
rm results
testout "" -b . listfilter test2 'Source(==simple)|(!Source,Package(==simple))'
ls -la results
cat > results.expected << END
test2|ugly|${FAKEARCHITECTURE}: simple 1
test2|ugly|coal: simple-addons 1
test2|ugly|source: simple 1
END
dodiff results.expected results
testout "" -b . listfilter test2 'Source(==bloat+-0a9z.app)|(!Source,Package(==bloat+-0a9z.app))'
cat > results.expected << END
test2|stupid|${FAKEARCHITECTURE}: bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
test2|stupid|coal: bloat+-0a9z.app-addons 99:0.9-A:Z+a:z-0+aA.9zZ
test2|stupid|source: bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
END
dodiff results.expected results

cat >conf/updates <<END
Name: Test2toTest1
Method: copy:$WORKDIR
VerifyRelease: blindtrust
Suite: test2
Architectures: coal>${FAKEARCHITECTURE} ${FAKEARCHITECTURE} source
FilterFormula: Priority(==optional),Package(>=alpha),Package(<=zeta)
FilterList: error list
ListHook: /bin/cp
END

cat >conf/list <<END
simple-addons		install
bloat+-0a9z.app 	install
simple			install
bloat+-0a9z.app-addons	install
END

cp dists/test2/Release dists/test2/Release.safe
ed -s dists/test2/Release <<EOF
g/stupid.source.Sources/s/^ ................................ / ffffffffffffffffffffffffffffffff /
w
q
EOF

testrun - -b . update test1 3<<EOF
returns 254
stderr
=WARNING: Single-Instance not yet supported!
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/Release'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/Release'
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/ugly/source/Sources.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/ugly/source/Sources.bz2'
-v2*=Uncompress './lists/Test2toTest1_test2_ugly_Sources.bz2' into './lists/Test2toTest1_test2_ugly_Sources' using '/bin/bunzip2'...
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages.bz2'
-v2*=Uncompress './lists/Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages.bz2' into './lists/Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages' using '/bin/bunzip2'...
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/ugly/binary-coal/Packages.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/ugly/binary-coal/Packages.bz2'
-v2*=Uncompress './lists/Test2toTest1_test2_ugly_coal_Packages.bz2' into './lists/Test2toTest1_test2_ugly_coal_Packages' using '/bin/bunzip2'...
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
*=Wrong checksum during receive of 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2':
*=md5 expected: ffffffffffffffffffffffffffffffff, got: $(md5 dists/test2/stupid/source/Sources.bz2)
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages.bz2'
-v2*=Uncompress './lists/Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages.bz2' into './lists/Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages' using '/bin/bunzip2'...
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/stupid/binary-coal/Packages.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/stupid/binary-coal/Packages.bz2'
-v2*=Uncompress './lists/Test2toTest1_test2_stupid_coal_Packages.bz2' into './lists/Test2toTest1_test2_stupid_coal_Packages' using '/bin/bunzip2'...
-v0*=There have been errors!
stdout
-v2*=Created directory "./lists"
EOF

cp dists/test2/Release.safe dists/test2/Release
ed -s dists/test2/Release <<EOF
g/stupid.source.Sources/s/^ ........................................ / 1111111111111111111111111111111111111111 /
w
q
EOF

testrun - -b . update test1 3<<EOF
returns 254
stderr
=WARNING: Single-Instance not yet supported!
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/Release'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/Release'
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
*=Wrong checksum during receive of 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2':
*=sha1 expected: 1111111111111111111111111111111111111111, got: $(sha1 dists/test2/stupid/source/Sources.bz2)
-v0*=There have been errors!
stdout
EOF

cp dists/test2/Release.safe dists/test2/Release
ed -s dists/test2/Release <<EOF
g/stupid.source.Sources/s/^ ................................................................ / 9999999999999999999999999999999999999999999999999999999999999999 /
w
q
EOF

testrun - -b . update test1 3<<EOF
returns 254
stderr
=WARNING: Single-Instance not yet supported!
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/Release'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/Release'
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
*=Wrong checksum during receive of 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2':
*=sha256 expected: 9999999999999999999999999999999999999999999999999999999999999999, got: $(sha256 dists/test2/stupid/source/Sources.bz2)
-v0*=There have been errors!
stdout
EOF

cp conf/updates conf/updates.safe
cat >> conf/updates <<EOF
IgnoreHashes: sha2
EOF

testrun - -b . update test1 3<<EOF
returns 248
stderr
*=Error parsing config file ./conf/updates, line 9, column 15:
*=Unknown flag in IgnoreHashes header.(allowed values: sha1 and sha256)
*=To ignore unknown fields use --ignore=unknownfield
-v0*=There have been errors!
stdout
EOF

cp conf/updates.safe conf/updates
cat >> conf/updates <<EOF
IgnoreHashes: sha1
EOF

testrun - -b . update test1 3<<EOF
returns 254
stderr
=WARNING: Single-Instance not yet supported!
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/Release'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/Release'
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2'
*=Wrong checksum during receive of 'copy:$WORKDIR/dists/test2/stupid/source/Sources.bz2':
*=sha256 expected: 9999999999999999999999999999999999999999999999999999999999999999, got: $(sha256 dists/test2/stupid/source/Sources.bz2)
-v0*=There have been errors!
stdout
EOF

cp conf/updates.safe conf/updates
cat >> conf/updates <<EOF
IgnoreHashes: sha256
EOF

testrun - -b . update test1 3<<EOF
stderr
=WARNING: Single-Instance not yet supported!
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/Release'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/Release'
-v2*=Uncompress './lists/Test2toTest1_test2_stupid_Sources.bz2' into './lists/Test2toTest1_test2_stupid_Sources'...
-v6*=Called /bin/cp './lists/Test2toTest1_test2_ugly_Sources' './lists/_test1_ugly_source_Test2toTest1_Test2toTest1_test2_ugly_Sources'
-v6*=Listhook successfully returned!
-v6*=Called /bin/cp './lists/Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages' './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_ugly_coal_Packages' './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_coal_Packages'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_stupid_Sources' './lists/_test1_stupid_source_Test2toTest1_Test2toTest1_test2_stupid_Sources'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages' './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_stupid_coal_Packages' './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_coal_Packages'
stdout
-v0*=Calculating packages to get...
-v3*=  processing updates for 'test1|ugly|source'
-v5*=  reading './lists/_test1_ugly_source_Test2toTest1_Test2toTest1_test2_ugly_Sources'
-v3*=  processing updates for 'test1|ugly|${FAKEARCHITECTURE}'
-v5*=  reading './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages'
-v5*=  reading './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_coal_Packages'
-v3*=  processing updates for 'test1|stupid|source'
-v5*=  reading './lists/_test1_stupid_source_Test2toTest1_Test2toTest1_test2_stupid_Sources'
-v3*=  processing updates for 'test1|stupid|${FAKEARCHITECTURE}'
-v5*=  reading './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages'
-v5*=  reading './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_coal_Packages'
-v0*=Getting packages...
-v1=Freeing some memory...
-v1*=Shutting down aptmethods...
-v0*=Installing (and possibly deleting) packages...
-d1*=db: 'simple' added to packages.db(test1|ugly|source).
-d1*=db: 'simple' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'simple-addons' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|stupid|source).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app-addons' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-v1*=Retracking test1...
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|source'...
-v6*=  replacing './dists/test1/ugly/source/Sources' (gzipped,bzip2ed)
EOF

mv dists/test2/Release.safe dists/test2/Release
mv conf/updates.safe conf/updates

checklog log1 <<EOF
DATESTR add test1 dsc ugly source simple 1
DATESTR add test1 deb ugly ${FAKEARCHITECTURE} simple 1
DATESTR add test1 deb ugly ${FAKEARCHITECTURE} simple-addons 1
DATESTR add test1 dsc stupid source bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} bloat+-0a9z.app-addons 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
checknolog log1
checknolog log2
testrun - -b . update test1 3<<EOF
=WARNING: Single-Instance not yet supported!
-v6*=aptmethod start 'copy:$WORKDIR/dists/test2/Release'
-v1*=aptmethod got 'copy:$WORKDIR/dists/test2/Release'
stdout
-v0*=Nothing to do found. (Use --noskipold to force processing)
EOF
checklog log1 < /dev/null
checknolog log2
testrun - --nolistsdownload --noskipold -b . update test1 3<<EOF
=WARNING: Single-Instance not yet supported!
-v6*=Called /bin/cp './lists/Test2toTest1_test2_ugly_Sources' './lists/_test1_ugly_source_Test2toTest1_Test2toTest1_test2_ugly_Sources'
-v6*=Listhook successfully returned!
-v6*=Called /bin/cp './lists/Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages' './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_ugly_coal_Packages' './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_coal_Packages'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_stupid_Sources' './lists/_test1_stupid_source_Test2toTest1_Test2toTest1_test2_stupid_Sources'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages' './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages'
-v6*=Called /bin/cp './lists/Test2toTest1_test2_stupid_coal_Packages' './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_coal_Packages'
stdout
-v0*=Calculating packages to get...
-v3*=  processing updates for 'test1|ugly|source'
-v5*=  reading './lists/_test1_ugly_source_Test2toTest1_Test2toTest1_test2_ugly_Sources'
-v3*=  processing updates for 'test1|ugly|${FAKEARCHITECTURE}'
-v5*=  reading './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_${FAKEARCHITECTURE}_Packages'
-v5*=  reading './lists/_test1_ugly_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_ugly_coal_Packages'
-v3*=  processing updates for 'test1|stupid|source'
-v5*=  reading './lists/_test1_stupid_source_Test2toTest1_Test2toTest1_test2_stupid_Sources'
-v3*=  processing updates for 'test1|stupid|${FAKEARCHITECTURE}'
-v5*=  reading './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_${FAKEARCHITECTURE}_Packages'
-v5*=  reading './lists/_test1_stupid_${FAKEARCHITECTURE}_Test2toTest1_Test2toTest1_test2_stupid_coal_Packages'
-v0*=Getting packages...
-v1=Freeing some memory...
-v1*=Shutting down aptmethods...
-v0*=Installing (and possibly deleting) packages...
EOF
checklog log1 < /dev/null
checknolog log2

find dists/test2/ \( -name "Packages.gz" -o -name "Sources.gz" \) -print0 | xargs -0 zgrep '^Package: ' | sed -e 's/test2/test1/' -e "s/coal/${FAKEARCHITECTURE}/" | sort > test2
find dists/test1/ \( -name "Packages.gz" -o -name "Sources.gz" \) -print0 | xargs -0 zgrep '^Package: ' | sort > test1
dodiff test2 test1

testrun - -b . check test1 test2 3<<EOF
stdout
-v1*=Checking test2...
-x1*=Checking packages in 'test2|stupid|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test2|stupid|coal'...
-x1*=Checking packages in 'test2|stupid|source'...
-x1*=Checking packages in 'test2|ugly|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test2|ugly|coal'...
-x1*=Checking packages in 'test2|ugly|source'...
-v1*=Checking test1...
-x1*=Checking packages in 'test1|stupid|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test1|stupid|source'...
-x1*=Checking packages in 'test1|ugly|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test1|ugly|source'...
EOF
testrun "" -b . checkpool
testrun - -b . rereference test1 test2 3<<EOF
stdout
-v1*=Referencing test2...
-v2=Rereferencing test2|stupid|${FAKEARCHITECTURE}...
-v2=Rereferencing test2|stupid|coal...
-v2=Rereferencing test2|stupid|source...
-v2=Rereferencing test2|ugly|${FAKEARCHITECTURE}...
-v2=Rereferencing test2|ugly|coal...
-v2=Rereferencing test2|ugly|source...
-v3*=Unlocking dependencies of test2|stupid|${FAKEARCHITECTURE}...
-v3*=Referencing test2|stupid|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test2|stupid|coal...
-v3*=Referencing test2|stupid|coal...
-v3*=Unlocking dependencies of test2|stupid|source...
-v3*=Referencing test2|stupid|source...
-v3*=Unlocking dependencies of test2|ugly|${FAKEARCHITECTURE}...
-v3*=Referencing test2|ugly|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test2|ugly|coal...
-v3*=Referencing test2|ugly|coal...
-v3*=Unlocking dependencies of test2|ugly|source...
-v3*=Referencing test2|ugly|source...
-v1*=Referencing test1...
-v2=Rereferencing test1|stupid|${FAKEARCHITECTURE}...
-v2=Rereferencing test1|stupid|source...
-v2=Rereferencing test1|ugly|${FAKEARCHITECTURE}...
-v2=Rereferencing test1|ugly|source...
-v3*=Unlocking dependencies of test1|stupid|${FAKEARCHITECTURE}...
-v3*=Referencing test1|stupid|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test1|stupid|source...
-v3*=Referencing test1|stupid|source...
-v3*=Unlocking dependencies of test1|ugly|${FAKEARCHITECTURE}...
-v3*=Referencing test1|ugly|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test1|ugly|source...
-v3*=Referencing test1|ugly|source...
EOF
testrun - -b . check test1 test2 3<<EOF
stdout
-v1*=Checking test1...
-x1*=Checking packages in 'test2|stupid|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test2|stupid|coal'...
-x1*=Checking packages in 'test2|stupid|source'...
-x1*=Checking packages in 'test2|ugly|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test2|ugly|coal'...
-x1*=Checking packages in 'test2|ugly|source'...
-v1*=Checking test2...
-x1*=Checking packages in 'test1|stupid|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test1|stupid|source'...
-x1*=Checking packages in 'test1|ugly|${FAKEARCHITECTURE}'...
-x1*=Checking packages in 'test1|ugly|source'...
EOF

testout "" -b . dumptracks
cat >results.expected <<END
Distribution: test1
Source: bloat+-0a9z.app
Version: 99:0.9-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb a 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc s 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz s 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes c 0
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb a 1
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc s 1
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz s 1

Distribution: test1
Source: simple
Version: 1
Files:
 pool/stupid/s/simple/simple-addons_1_all.deb a 0
 pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 0
 pool/stupid/s/simple/simple_1.dsc s 0
 pool/stupid/s/simple/simple_1.tar.gz s 0
 pool/stupid/s/simple/simple_1_source+${FAKEARCHITECTURE}+all.changes c 0
 pool/ugly/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 1
 pool/ugly/s/simple/simple-addons_1_all.deb a 1
 pool/ugly/s/simple/simple_1.dsc s 1
 pool/ugly/s/simple/simple_1.tar.gz s 1

END
dodiff results.expected results

testout "" -b . dumpunreferenced
dodiff results.empty results
testrun - -b . removealltracks test2 test1 3<<EOF
stdout
stderr
*=Error: Requested removing of all tracks of distribution 'test1',
*=which still has tracking enabled. Use --delete to delete anyway.
-v0*=There have been errors!
returns 255
EOF
testrun - --delete -b . removealltracks test2 test1 3<<EOF
stdout
-v0*=Deleting all tracks for test2...
-v0*=Deleting all tracks for test1...
-v0*=Deleting files no longer referenced...
-v1*=deleting and forgetting pool/stupid/s/simple/simple-addons_1_all.deb
-d1*=db: 'pool/stupid/s/simple/simple-addons_1_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/s/simple/simple_1.dsc
-d1*=db: 'pool/stupid/s/simple/simple_1.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/s/simple/simple_1.tar.gz
-d1*=db: 'pool/stupid/s/simple/simple_1.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/s/simple/simple_1_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/stupid/s/simple/simple_1_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/stupid/s/simple
-v2*=removed now empty directory ./pool/stupid/s
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/ugly/b/bloat+-0a9z.app
-v2*=removed now empty directory ./pool/ugly/b
EOF
echo returned: $?
testrun - -b . include test1 test.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
stdout
-v2*=Created directory "./pool/ugly/b"
-v2*=Created directory "./pool/ugly/b/bloat+-0a9z.app"
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: 'bloat+-0a9z.app-addons' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|ugly|source).
-d1*=db: 'bloat+-0a9z.app' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|source'...
-v6*=  replacing './dists/test1/ugly/source/Sources' (gzipped,bzip2ed)
EOF
checklog log1 <<EOF
DATESTR add test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app-addons 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR add test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR add test1 dsc ugly source bloat+-0a9z.app 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
echo returned: $?
OUTPUT=test2.changes PACKAGE=bloat+-0a9z.app EPOCH=99: VERSION=9.0-A:Z+a:z REVISION=-0+aA.9zZ SECTION="ugly/extra" genpackage.sh
testrun - -b . include test1 test2.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
stdout
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc' added to checksums.db(pool).
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:9.0-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: 'bloat+-0a9z.app-addons' removed from packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app-addons' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' removed from packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'bloat+-0a9z.app' removed from packages.db(test1|ugly|source).
-d1*=db: 'bloat+-0a9z.app' added to packages.db(test1|ugly|source).
-d1*=db: 'bloat+-0a9z.app' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|source'...
-v6*=  replacing './dists/test1/ugly/source/Sources' (gzipped,bzip2ed)
EOF
echo returned: $?
checklog log1 <<EOF
DATESTR replace test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app-addons 99:9.0-A:Z+a:z-0+aA.9zZ 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR replace test1 deb ugly ${FAKEARCHITECTURE} bloat+-0a9z.app 99:9.0-A:Z+a:z-0+aA.9zZ 99:0.9-A:Z+a:z-0+aA.9zZ
DATESTR replace test1 dsc ugly source bloat+-0a9z.app 99:9.0-A:Z+a:z-0+aA.9zZ 99:0.9-A:Z+a:z-0+aA.9zZ
EOF
testrun - -b . -S sectiontest -P prioritytest includedeb test1 simple_1_${FAKEARCHITECTURE}.deb 3<<EOF
stderr
-v1*=simple_1_${FAKEARCHITECTURE}.deb: component guessed as 'stupid'
stdout
-v2*=Created directory "./pool/stupid/s"
-v2*=Created directory "./pool/stupid/s/simple"
-d1*=db: 'pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'simple' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'simple' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
echo returned: $?
dodo zgrep '^Section: sectiontest' dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages.gz
dodo zgrep '^Priority: prioritytest' dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages.gz
checklog log1 <<EOF
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} simple 1
EOF
testrun - -b . -S sectiontest -P prioritytest includedsc test1 simple_1.dsc 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
-v1*=simple_1.dsc: component guessed as 'stupid'
stdout
-d1*=db: 'pool/stupid/s/simple/simple_1.dsc' added to checksums.db(pool).
-d1*=db: 'pool/stupid/s/simple/simple_1.tar.gz' added to checksums.db(pool).
-d1*=db: 'simple' added to packages.db(test1|stupid|source).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
echo returned: $?
dodo zgrep '^Section: sectiontest' dists/test1/stupid/source/Sources.gz
dodo zgrep '^Priority: prioritytest' dists/test1/stupid/source/Sources.gz
checklog log1 <<EOF
DATESTR add test1 dsc stupid source simple 1
EOF

testout "" -b . dumptracks
cat >results.expected <<END
Distribution: test1
Source: bloat+-0a9z.app
Version: 99:0.9-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb a 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc s 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz s 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: bloat+-0a9z.app
Version: 99:9.0-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb a 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:9.0-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: simple
Version: 1
Files:
 pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/s/simple/simple_1.dsc s 1
 pool/stupid/s/simple/simple_1.tar.gz s 1

END
dodiff results.expected results
testout "" -b . dumpunreferenced
dodiff results.empty results

echo "now testing .orig.tar.gz handling"
tar -czf test_1.orig.tar.gz test.changes
PACKAGE=test EPOCH="" VERSION=1 REVISION="-2" SECTION="stupid/base" genpackage.sh -sd
testrun - -b . include test1 test.changes 3<<EOF
returns 249
stderr
-v0=Data seems not to be signed trying to use directly...
*=Unable to find pool/stupid/t/test/test_1.orig.tar.gz needed by test_1-2.dsc!
*=Perhaps you forgot to give dpkg-buildpackage the -sa option,
*= or you could try --ignore=missingfile to guess possible files to use.
-v0*=There have been errors!
stdout
-v2*=Created directory "./pool/stupid/t"
-v2*=Created directory "./pool/stupid/t/test"
-d1*=db: 'pool/stupid/t/test/test-addons_1-2_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1-2.diff.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1-2.dsc' added to checksums.db(pool).
-v0*=Deleting files just added to the pool but not used (to avoid use --keepunusednewfiles next time)
-v1*=deleting and forgetting pool/stupid/t/test/test-addons_1-2_all.deb
-d1*=db: 'pool/stupid/t/test/test-addons_1-2_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1-2.diff.gz
-d1*=db: 'pool/stupid/t/test/test_1-2.diff.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1-2.dsc
-d1*=db: 'pool/stupid/t/test/test_1-2.dsc' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/stupid/t/test
-v2*=removed now empty directory ./pool/stupid/t
EOF
checknolog log1
checknolog log2
testrun - -b . --ignore=missingfile include test1 test.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
*=Unable to find pool/stupid/t/test/test_1.orig.tar.gz!
*=Perhaps you forgot to give dpkg-buildpackage the -sa option.
*=--ignore=missingfile was given, searching for file...
stdout
-v2*=Created directory "./pool/stupid/t"
-v2*=Created directory "./pool/stupid/t/test"
-d1*=db: 'pool/stupid/t/test/test-addons_1-2_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1-2.diff.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1-2.dsc' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1.orig.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/test/test_1-2_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: 'test-addons' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'test' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'test' added to packages.db(test1|stupid|source).
-d1*=db: 'test' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} test-addons 1-2
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} test 1-2
DATESTR add test1 dsc stupid source test 1-2
EOF
dodo zgrep test_1-2.dsc dists/test1/stupid/source/Sources.gz

tar -czf testb_2.orig.tar.gz test.changes
PACKAGE=testb EPOCH="1:" VERSION=2 REVISION="-2" SECTION="stupid/base" genpackage.sh -sa
testrun - -b . include test1 test.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
stdout
-v2*=Created directory "./pool/stupid/t/testb"
-d1*=db: 'pool/stupid/t/testb/testb-addons_2-2_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_2-2_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_2-2.diff.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_2-2.dsc' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_2.orig.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_1:2-2_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: 'testb-addons' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'testb' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'testb' added to packages.db(test1|stupid|source).
-d1*=db: 'testb' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} testb-addons 1:2-2
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} testb 1:2-2
DATESTR add test1 dsc stupid source testb 1:2-2
EOF
dodo zgrep testb_2-2.dsc dists/test1/stupid/source/Sources.gz
rm test2.changes
PACKAGE=testb EPOCH="1:" VERSION=2 REVISION="-3" SECTION="stupid/base" OUTPUT="test2.changes" genpackage.sh -sd
testrun - -b . include test1 test2.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
stdout
-d1*=db: 'pool/stupid/t/testb/testb-addons_2-3_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_2-3_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_2-3.diff.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_2-3.dsc' added to checksums.db(pool).
-d1*=db: 'pool/stupid/t/testb/testb_1:2-3_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: 'testb-addons' removed from packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'testb-addons' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'testb' removed from packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'testb' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'testb' removed from packages.db(test1|stupid|source).
-d1*=db: 'testb' added to packages.db(test1|stupid|source).
-d1*=db: 'testb' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR replace test1 deb stupid ${FAKEARCHITECTURE} testb-addons 1:2-3 1:2-2
DATESTR replace test1 deb stupid ${FAKEARCHITECTURE} testb 1:2-3 1:2-2
DATESTR replace test1 dsc stupid source testb 1:2-3 1:2-2
EOF
dodo zgrep testb_2-3.dsc dists/test1/stupid/source/Sources.gz

testout "" -b . dumpunreferenced
dodiff results.empty results

echo "now testing some error messages:"
PACKAGE=4test EPOCH="1:" VERSION=b.1 REVISION="-1" SECTION="stupid/base" genpackage.sh
testrun -  -b . include test1 test.changes 3<<EOF
stderr
-v0=Data seems not to be signed trying to use directly...
stdout
-v2*=Created directory "./pool/stupid/4"
-v2*=Created directory "./pool/stupid/4/4test"
-d1*=db: 'pool/stupid/4/4test/4test-addons_b.1-1_all.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/4/4test/4test_b.1-1.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/4/4test/4test_b.1-1.dsc' added to checksums.db(pool).
-d1*=db: 'pool/stupid/4/4test/4test_1:b.1-1_source+${FAKEARCHITECTURE}+all.changes' added to checksums.db(pool).
-d1*=db: '4test-addons' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: '4test' added to packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: '4test' added to packages.db(test1|stupid|source).
-d1*=db: '4test' added to tracking.db(test1).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test1|ugly|source'...
EOF
checklog log1 <<EOF
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} 4test-addons 1:b.1-1
DATESTR add test1 deb stupid ${FAKEARCHITECTURE} 4test 1:b.1-1
DATESTR add test1 dsc stupid source 4test 1:b.1-1
EOF

cat >includeerror.rules <<EOF
returns 255
stderr
-v0*=There have been errors!
*=Error: Too few arguments for command 'include'!
*=Syntax: reprepro [--delete] include <distribution> <.changes-file>
EOF
testrun includeerror -b . include unknown 3<<EOF
testrun includeerror -b . include unknown test.changes test2.changes
testrun - -b . include unknown test.changes 3<<EOF
stderr
-v0*=There have been errors!
*=No distribution definition of 'unknown' found in './conf/distributions'!
returns 249
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results

testout "" -b . dumptracks
# TODO: check those if they are really expected...
cat > results.expected <<EOF
Distribution: test1
Source: 4test
Version: 1:b.1-1
Files:
 pool/stupid/4/4test/4test-addons_b.1-1_all.deb a 1
 pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/4/4test/4test_b.1-1.dsc s 1
 pool/stupid/4/4test/4test_b.1-1.tar.gz s 1
 pool/stupid/4/4test/4test_1:b.1-1_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: bloat+-0a9z.app
Version: 99:0.9-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb a 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc s 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz s 0
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: bloat+-0a9z.app
Version: 99:9.0-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb a 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:9.0-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: simple
Version: 1
Files:
 pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/s/simple/simple_1.dsc s 1
 pool/stupid/s/simple/simple_1.tar.gz s 1

Distribution: test1
Source: test
Version: 1-2
Files:
 pool/stupid/t/test/test-addons_1-2_all.deb a 1
 pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/test/test_1-2.dsc s 1
 pool/stupid/t/test/test_1.orig.tar.gz s 1
 pool/stupid/t/test/test_1-2.diff.gz s 1
 pool/stupid/t/test/test_1-2_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: testb
Version: 1:2-2
Files:
 pool/stupid/t/testb/testb-addons_2-2_all.deb a 0
 pool/stupid/t/testb/testb_2-2_${FAKEARCHITECTURE}.deb b 0
 pool/stupid/t/testb/testb_2-2.dsc s 0
 pool/stupid/t/testb/testb_2.orig.tar.gz s 0
 pool/stupid/t/testb/testb_2-2.diff.gz s 0
 pool/stupid/t/testb/testb_1:2-2_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: testb
Version: 1:2-3
Files:
 pool/stupid/t/testb/testb-addons_2-3_all.deb a 1
 pool/stupid/t/testb/testb_2-3_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/testb/testb_2-3.dsc s 1
 pool/stupid/t/testb/testb_2.orig.tar.gz s 1
 pool/stupid/t/testb/testb_2-3.diff.gz s 1
 pool/stupid/t/testb/testb_1:2-3_source+${FAKEARCHITECTURE}+all.changes c 0

EOF
dodiff results.expected results
testrun -  -b . tidytracks 3<<EOF
stdout
-v0*=Looking for old tracks in test1...
EOF
testout "" -b . dumptracks
dodiff results.expected results
sed -i -e 's/^Tracking: keep/Tracking: all/' conf/distributions
testrun -  -b . tidytracks 3<<EOF
stdout
-v0*=Looking for old tracks in test1...
-d1*=db: 'testb' '1:2-2' removed from tracking.db(test1).
-d1*=db: 'bloat+-0a9z.app' '99:0.9-A:Z+a:z-0+aA.9zZ' removed from tracking.db(test1).
-v0*=Deleting files no longer referenced...
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:0.9-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb-addons_2-2_all.deb
-d1*=db: 'pool/stupid/t/testb/testb-addons_2-2_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_2-2_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/t/testb/testb_2-2_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_2-2.dsc
-d1*=db: 'pool/stupid/t/testb/testb_2-2.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_2-2.diff.gz
-d1*=db: 'pool/stupid/t/testb/testb_2-2.diff.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_1:2-2_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/stupid/t/testb/testb_1:2-2_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
EOF
cp db/tracking.db db/saved2tracking.db
cp db/references.db db/saved2references.db
testout "" -b . dumpunreferenced
dodiff results.empty results
testout "" -b . dumptracks
cat > results.expected <<EOF
Distribution: test1
Source: 4test
Version: 1:b.1-1
Files:
 pool/stupid/4/4test/4test-addons_b.1-1_all.deb a 1
 pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/4/4test/4test_b.1-1.dsc s 1
 pool/stupid/4/4test/4test_b.1-1.tar.gz s 1
 pool/stupid/4/4test/4test_1:b.1-1_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: bloat+-0a9z.app
Version: 99:9.0-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb a 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:9.0-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: simple
Version: 1
Files:
 pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/s/simple/simple_1.dsc s 1
 pool/stupid/s/simple/simple_1.tar.gz s 1

Distribution: test1
Source: test
Version: 1-2
Files:
 pool/stupid/t/test/test-addons_1-2_all.deb a 1
 pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/test/test_1-2.dsc s 1
 pool/stupid/t/test/test_1.orig.tar.gz s 1
 pool/stupid/t/test/test_1-2.diff.gz s 1
 pool/stupid/t/test/test_1-2_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: testb
Version: 1:2-3
Files:
 pool/stupid/t/testb/testb-addons_2-3_all.deb a 1
 pool/stupid/t/testb/testb_2-3_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/testb/testb_2-3.dsc s 1
 pool/stupid/t/testb/testb_2.orig.tar.gz s 1
 pool/stupid/t/testb/testb_2-3.diff.gz s 1
 pool/stupid/t/testb/testb_1:2-3_source+${FAKEARCHITECTURE}+all.changes c 0

EOF
dodiff results.expected results
sed -i -e 's/^Tracking: all/Tracking: minimal/' conf/distributions
testrun -  -b . tidytracks 3<<EOF
stdout
-v0*=Looking for old tracks in test1...
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results
testout "" -b . dumptracks
dodiff results.expected results
sed -i -e 's/^Tracking: minimal includechanges/Tracking: minimal/' conf/distributions
testrun -  -b . tidytracks 3<<EOF
stdout
-v0*=Looking for old tracks in test1...
-v0*=Deleting files no longer referenced...
-v1*=deleting and forgetting pool/stupid/4/4test/4test_1:b.1-1_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/stupid/4/4test/4test_1:b.1-1_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:9.0-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:9.0-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1-2_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/stupid/t/test/test_1-2_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_1:2-3_source+${FAKEARCHITECTURE}+all.changes
-d1*=db: 'pool/stupid/t/testb/testb_1:2-3_source+${FAKEARCHITECTURE}+all.changes' removed from checksums.db(pool).
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results
testout "" -b . dumptracks
cat > results.expected <<EOF
Distribution: test1
Source: 4test
Version: 1:b.1-1
Files:
 pool/stupid/4/4test/4test-addons_b.1-1_all.deb a 1
 pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/4/4test/4test_b.1-1.dsc s 1
 pool/stupid/4/4test/4test_b.1-1.tar.gz s 1

Distribution: test1
Source: bloat+-0a9z.app
Version: 99:9.0-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb a 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz s 1

Distribution: test1
Source: simple
Version: 1
Files:
 pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/s/simple/simple_1.dsc s 1
 pool/stupid/s/simple/simple_1.tar.gz s 1

Distribution: test1
Source: test
Version: 1-2
Files:
 pool/stupid/t/test/test-addons_1-2_all.deb a 1
 pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/test/test_1-2.dsc s 1
 pool/stupid/t/test/test_1.orig.tar.gz s 1
 pool/stupid/t/test/test_1-2.diff.gz s 1

Distribution: test1
Source: testb
Version: 1:2-3
Files:
 pool/stupid/t/testb/testb-addons_2-3_all.deb a 1
 pool/stupid/t/testb/testb_2-3_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/testb/testb_2-3.dsc s 1
 pool/stupid/t/testb/testb_2.orig.tar.gz s 1
 pool/stupid/t/testb/testb_2-3.diff.gz s 1

EOF
dodiff results.expected results
testrun -  -b . tidytracks 3<<EOF
stdout
-v0*=Looking for old tracks in test1...
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results
# Earlier update rules made this tracking data outdated.
# so copy it, so it can be replayed so that also outdated data
# is tested to be handled correctly.
mv db/tracking.db db/savedtracking.db
mv db/references.db db/savedreferences.db
# Try this with .changes files still listed
mv db/saved2tracking.db db/tracking.db
mv db/saved2references.db db/references.db
sed -i -e 's/^Tracking: minimal/Tracking: minimal includechanges/' conf/distributions
testrun -  -b . retrack 3<<EOF
stdout
-v1*=Retracking test1...
-d1*=db: 'bloat+-0a9z.app' added to tracking.db(test1).
-x1*=  Tracking test1|stupid|${FAKEARCHITECTURE}...
-x1*=  Tracking test1|stupid|source...
-x1*=  Tracking test1|ugly|${FAKEARCHITECTURE}...
-x1*=  Tracking test1|ugly|source...
EOF
testout "" -b . dumptracks
cat > results.expected <<EOF
Distribution: test1
Source: 4test
Version: 1:b.1-1
Files:
 pool/stupid/4/4test/4test-addons_b.1-1_all.deb a 1
 pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/4/4test/4test_b.1-1.dsc s 1
 pool/stupid/4/4test/4test_b.1-1.tar.gz s 1
 pool/stupid/4/4test/4test_1:b.1-1_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: bloat+-0a9z.app
Version: 99:0.9-A:Z+a:z-0+aA.9zZ
Files:
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb a 1
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc s 1
 pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz s 1

Distribution: test1
Source: bloat+-0a9z.app
Version: 99:9.0-A:Z+a:z-0+aA.9zZ
Files:
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb a 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb b 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz s 1
 pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_99:9.0-A:Z+a:z-0+aA.9zZ_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: simple
Version: 1
Files:
 pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/s/simple/simple_1.dsc s 1
 pool/stupid/s/simple/simple_1.tar.gz s 1
 pool/ugly/s/simple/simple_1_${FAKEARCHITECTURE}.deb b 1
 pool/ugly/s/simple/simple-addons_1_all.deb a 1
 pool/ugly/s/simple/simple_1.dsc s 1
 pool/ugly/s/simple/simple_1.tar.gz s 1

Distribution: test1
Source: test
Version: 1-2
Files:
 pool/stupid/t/test/test-addons_1-2_all.deb a 1
 pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/test/test_1-2.dsc s 1
 pool/stupid/t/test/test_1.orig.tar.gz s 1
 pool/stupid/t/test/test_1-2.diff.gz s 1
 pool/stupid/t/test/test_1-2_source+${FAKEARCHITECTURE}+all.changes c 0

Distribution: test1
Source: testb
Version: 1:2-3
Files:
 pool/stupid/t/testb/testb-addons_2-3_all.deb a 1
 pool/stupid/t/testb/testb_2-3_${FAKEARCHITECTURE}.deb b 1
 pool/stupid/t/testb/testb_2-3.dsc s 1
 pool/stupid/t/testb/testb_2.orig.tar.gz s 1
 pool/stupid/t/testb/testb_2-3.diff.gz s 1
 pool/stupid/t/testb/testb_1:2-3_source+${FAKEARCHITECTURE}+all.changes c 0

EOF
dodiff results.expected results

testout "" -b . dumpunreferenced
dodiff results.empty results
testout ""  -b . dumpreferences
cp results results.expected
testrun - -b . rereference 3<<EOF
stdout
-v1*=Referencing test1...
-v3*=Unlocking dependencies of test1|stupid|${FAKEARCHITECTURE}...
=Rereferencing test1|stupid|${FAKEARCHITECTURE}...
-v3*=Referencing test1|stupid|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test1|stupid|source...
=Rereferencing test1|stupid|source...
-v3*=Referencing test1|stupid|source...
-v3*=Unlocking dependencies of test1|ugly|${FAKEARCHITECTURE}...
=Rereferencing test1|ugly|${FAKEARCHITECTURE}...
-v3*=Referencing test1|ugly|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test1|ugly|source...
=Rereferencing test1|ugly|source...
-v3*=Referencing test1|ugly|source...
-v1*=Referencing test2...
-v3*=Unlocking dependencies of test2|stupid|${FAKEARCHITECTURE}...
=Rereferencing test2|stupid|${FAKEARCHITECTURE}...
-v3*=Referencing test2|stupid|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test2|stupid|coal...
=Rereferencing test2|stupid|coal...
-v3*=Referencing test2|stupid|coal...
-v3*=Unlocking dependencies of test2|stupid|source...
=Rereferencing test2|stupid|source...
-v3*=Referencing test2|stupid|source...
-v3*=Unlocking dependencies of test2|ugly|${FAKEARCHITECTURE}...
=Rereferencing test2|ugly|${FAKEARCHITECTURE}...
-v3*=Referencing test2|ugly|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test2|ugly|coal...
=Rereferencing test2|ugly|coal...
-v3*=Referencing test2|ugly|coal...
-v3*=Unlocking dependencies of test2|ugly|source...
=Rereferencing test2|ugly|source...
-v3*=Referencing test2|ugly|source...
EOF
testout ""  -b . dumpreferences
dodiff results results.expected
rm db/references.db
testrun - -b . rereference 3<<EOF
stdout
-v1*=Referencing test1...
-v3*=Unlocking dependencies of test1|stupid|${FAKEARCHITECTURE}...
=Rereferencing test1|stupid|${FAKEARCHITECTURE}...
-v3*=Referencing test1|stupid|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test1|stupid|source...
=Rereferencing test1|stupid|source...
-v3*=Referencing test1|stupid|source...
-v3*=Unlocking dependencies of test1|ugly|${FAKEARCHITECTURE}...
=Rereferencing test1|ugly|${FAKEARCHITECTURE}...
-v3*=Referencing test1|ugly|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test1|ugly|source...
=Rereferencing test1|ugly|source...
-v3*=Referencing test1|ugly|source...
-v1*=Referencing test2...
-v3*=Unlocking dependencies of test2|stupid|${FAKEARCHITECTURE}...
=Rereferencing test2|stupid|${FAKEARCHITECTURE}...
-v3*=Referencing test2|stupid|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test2|stupid|coal...
=Rereferencing test2|stupid|coal...
-v3*=Referencing test2|stupid|coal...
-v3*=Unlocking dependencies of test2|stupid|source...
=Rereferencing test2|stupid|source...
-v3*=Referencing test2|stupid|source...
-v3*=Unlocking dependencies of test2|ugly|${FAKEARCHITECTURE}...
=Rereferencing test2|ugly|${FAKEARCHITECTURE}...
-v3*=Referencing test2|ugly|${FAKEARCHITECTURE}...
-v3*=Unlocking dependencies of test2|ugly|coal...
=Rereferencing test2|ugly|coal...
-v3*=Referencing test2|ugly|coal...
-v3*=Unlocking dependencies of test2|ugly|source...
=Rereferencing test2|ugly|source...
-v3*=Referencing test2|ugly|source...
EOF
testout ""  -b . dumpreferences
dodiff results results.expected
testout ""  -b . dumpreferences
dodiff results.expected results

sed -i -e 's/^Tracking: minimal/Tracking: keep includechanges/' conf/distributions
mv db/savedtracking.db db/tracking.db
mv db/savedreferences.db db/references.db

mkdir conf2
testrun - -b . --confdir ./conf2 update 3<<EOF
returns 254
stderr
*=Error opening config file './conf2/distributions': No such file or directory(2)
=(Have you forgotten to specify a basedir by -b?
=To only set the conf/ dir use --confdir)
-v0*=There have been errors!
EOF
touch conf2/distributions
testrun - -b . --confdir ./conf2 update 3<<EOF
returns 249
stderr
*=No distribution definitions found in ./conf2/distributions!
-v0*=There have been errors!
EOF
echo 'Codename: foo' > conf2/distributions
testrun - -b . --confdir ./conf2 update 3<<EOF
stderr
*=Error parsing config file ./conf2/distributions, line 2:
*=Required field 'Architectures' expected (since line 1).
-v0*=There have been errors!
returns 249
EOF
echo "Architectures: ${FAKEARCHITECTURE} fingers" >> conf2/distributions
testrun - -b . --confdir ./conf2 update 3<<EOF
*=Error parsing config file ./conf2/distributions, line 3:
*=Required field 'Components' expected (since line 1).
-v0*=There have been errors!
returns 249
EOF
echo 'Components: unneeded bloated i386' >> conf2/distributions
testrun - -b . --confdir ./conf2 update 3<<EOF
*=Error: packages database contains unused 'test1|stupid|${FAKEARCHITECTURE}' database.
*=This either means you removed a distribution, component or architecture from
*=the distributions config file without calling clearvanished, or your config
*=does not belong to this database.
*=To ignore use --ignore=undefinedtarget.
-v0*=There have been errors!
returns 255
EOF
testrun - -b . --confdir ./conf2 --ignore=undefinedtarget update 3<<EOF
*=Error: packages database contains unused 'test1|stupid|${FAKEARCHITECTURE}' database.
*=This either means you removed a distribution, component or architecture from
*=the distributions config file without calling clearvanished, or your config
*=does not belong to this database.
*=Ignoring as --ignore=undefinedtarget given.
*=Error: packages database contains unused 'test1|ugly|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test1|ugly|source' database.
*=Error: packages database contains unused 'test1|stupid|source' database.
*=Error: packages database contains unused 'test2|stupid|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test2|stupid|coal' database.
*=Error: packages database contains unused 'test2|stupid|source' database.
*=Error: packages database contains unused 'test2|ugly|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test2|ugly|coal' database.
*=Error: packages database contains unused 'test2|ugly|source' database.
*=Error: tracking database contains unused 'test1' database.
*=This either means you removed a distribution from the distributions config
*=file without calling clearvanished (or at least removealltracks), you
*=experienced a bug in retrack in versions < 3.0.0, you found a new bug or your
*=config does not belong to this database.
*=To ignore use --ignore=undefinedtracking.
-v0*=There have been errors!
returns 255
EOF
testrun - -b . --confdir ./conf2 --ignore=undefinedtarget --ignore=undefinedtracking update 3<<EOF
*=Error: packages database contains unused 'test1|stupid|${FAKEARCHITECTURE}' database.
*=This either means you removed a distribution, component or architecture from
*=the distributions config file without calling clearvanished, or your config
*=does not belong to this database.
*=Ignoring as --ignore=undefinedtarget given.
*=Error: tracking database contains unused 'test1' database.
*=This either means you removed a distribution from the distributions config
*=file without calling clearvanished (or at least removealltracks), you
*=experienced a bug in retrack in versions < 3.0.0, you found a new bug or your
*=config does not belong to this database.
*=Ignoring as --ignore=undefinedtracking given.
*=Error: packages database contains unused 'test1|ugly|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test1|ugly|source' database.
*=Error: packages database contains unused 'test1|stupid|source' database.
*=Error: packages database contains unused 'test2|stupid|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test2|stupid|coal' database.
*=Error: packages database contains unused 'test2|stupid|source' database.
*=Error: packages database contains unused 'test2|ugly|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test2|ugly|coal' database.
*=Error: packages database contains unused 'test2|ugly|source' database.
*=Error opening config file './conf2/updates': No such file or directory(2)
-v0*=There have been errors!
returns 254
EOF
touch conf2/updates
testrun - -b . --confdir ./conf2 --ignore=undefinedtarget --ignore=undefinedtracking --noskipold update 3<<EOF
stderr
*=Error: packages database contains unused 'test1|stupid|${FAKEARCHITECTURE}' database.
*=This either means you removed a distribution, component or architecture from
*=the distributions config file without calling clearvanished, or your config
*=does not belong to this database.
*=Ignoring as --ignore=undefinedtarget given.
*=Error: packages database contains unused 'test1|ugly|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test1|ugly|source' database.
*=Error: packages database contains unused 'test1|stupid|source' database.
*=Error: packages database contains unused 'test2|stupid|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test2|stupid|coal' database.
*=Error: packages database contains unused 'test2|stupid|source' database.
*=Error: packages database contains unused 'test2|ugly|${FAKEARCHITECTURE}' database.
*=Error: packages database contains unused 'test2|ugly|coal' database.
*=Error: packages database contains unused 'test2|ugly|source' database.
*=Error: tracking database contains unused 'test1' database.
*=This either means you removed a distribution from the distributions config
*=file without calling clearvanished (or at least removealltracks), you
*=experienced a bug in retrack in versions < 3.0.0, you found a new bug or your
*=config does not belong to this database.
*=Ignoring as --ignore=undefinedtracking given.
*=Nothing to do, because no distribution has an Update: field.
EOF
testrun - -b . clearvanished 3<<EOF
stdout
*=Deleting vanished identifier 'foo|bloated|${FAKEARCHITECTURE}'.
*=Deleting vanished identifier 'foo|bloated|fingers'.
*=Deleting vanished identifier 'foo|i386|${FAKEARCHITECTURE}'.
*=Deleting vanished identifier 'foo|i386|fingers'.
*=Deleting vanished identifier 'foo|unneeded|${FAKEARCHITECTURE}'.
*=Deleting vanished identifier 'foo|unneeded|fingers'.
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results
echo "Format: 2.0" > broken.changes
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*=In 'broken.changes': Missing 'Date' field!
=To Ignore use --ignore=missingfield.
-v0*=There have been errors!
returns 255
EOF
echo "Date: today" >> broken.changes
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*=In 'broken.changes': Missing 'Source' field
-v0*=There have been errors!
returns 255
EOF
echo "Source: nowhere" >> broken.changes
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*=In 'broken.changes': Missing 'Binary' field
-v0*=There have been errors!
returns 255
EOF
echo "Binary: phantom" >> broken.changes
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*=In 'broken.changes': Missing 'Architecture' field
-v0*=There have been errors!
returns 255
EOF
echo "Architecture: brain" >> broken.changes
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*=In 'broken.changes': Missing 'Version' field
-v0*=There have been errors!
returns 255
EOF
echo "Version: old" >> broken.changes
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'old' does not start with a digit, violating 'should'-directive in policy 5.6.11
*=In 'broken.changes': Missing 'Distribution' field
-v0*=There have been errors!
returns 255
EOF
echo "Distribution: old" >> broken.changes
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'old' does not start with a digit, violating 'should'-directive in policy 5.6.11
*=In 'broken.changes': Missing 'Maintainer' field!
=To Ignore use --ignore=missingfield.
-v0*=There have been errors!
returns 255
EOF
echo "Distribution: old" >> broken.changes
testrun - -b . --ignore=missingfield include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'old' does not start with a digit, violating 'should'-directive in policy 5.6.11
*=In 'broken.changes': Missing 'Maintainer' field!
=Ignoring as --ignore=missingfield given.
*=In 'broken.changes': Missing 'Files' field!
-v0*=There have been errors!
returns 255
EOF
echo "Files:" >> broken.changes
testrun - -b . --ignore=missingfield include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'old' does not start with a digit, violating 'should'-directive in policy 5.6.11
*=In 'broken.changes': Missing 'Maintainer' field!
*=broken.changes: Not enough files in .changes!
=Ignoring as --ignore=missingfield given.
-v0*=There have been errors!
returns 255
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results
echo " $EMPTYMD5 section priority filename_version.tar.gz" >> broken.changes
testrun - -b . --ignore=missingfield include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'old' does not start with a digit, violating 'should'-directive in policy 5.6.11
=In 'broken.changes': Missing 'Maintainer' field!
=Ignoring as --ignore=missingfield given.
*=Warning: File 'filename_version.tar.gz' looks like source but does not start with 'nowhere_'!
=I hope you know what you do.
# grr, this message has really to improve...
=Warning: Package version 'version.tar.gz' does not start with a digit, violating 'should'-directive in policy 5.6.11
*=.changes put in a distribution not listed within it!
=To ignore use --ignore=wrongdistribution.
-v0*=There have been errors!
returns 255
EOF
cp conf/distributions conf/distributions.old
cat >> conf/distributions <<EOF

Codename: getmoreatoms
Architectures: brain
Components: test
EOF
testrun - -b . --ignore=unusedarch --ignore=surprisingarch --ignore=wrongdistribution --ignore=missingfield include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'old' does not start with a digit, violating 'should'-directive in policy 5.6.11
=Ignoring as --ignore=missingfield given.
=In 'broken.changes': Missing 'Maintainer' field!
=Warning: File 'filename_version.tar.gz' looks like source but does not start with 'nowhere_'!
=I hope you know what you do.
*=.changes put in a distribution not listed within it!
*=Ignoring as --ignore=wrongdistribution given.
*=Architecture header lists architecture 'brain', but no files for it!
*=Ignoring as --ignore=unusedarch given.
*='filename_version.tar.gz' looks like architecture 'source', but this is not listed in the Architecture-Header!
*=Ignoring as --ignore=surprisingarch given.
*=Cannot find file './filename_version.tar.gz' needed by 'broken.changes'!
-v0*=There have been errors!
returns 249
EOF

touch filename_version.tar.gz
testrun - -b . --ignore=unusedarch --ignore=surprisingarch --ignore=wrongdistribution --ignore=missingfield include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'old' does not start with a digit, violating 'should'-directive in policy 5.6.11
=Ignoring as --ignore=missingfield given.
=In 'broken.changes': Missing 'Maintainer' field!
=Warning: File 'filename_version.tar.gz' looks like source but does not start with 'nowhere_'!
=I hope you know what you do.
*=.changes put in a distribution not listed within it!
*=Ignoring as --ignore=wrongdistribution given.
*=Architecture header lists architecture 'brain', but no files for it!
*=Ignoring as --ignore=unusedarch given.
*='filename_version.tar.gz' looks like architecture 'source', but this is not listed in the Architecture-Header!
*=Ignoring as --ignore=surprisingarch given.
stdout
-v2*=Created directory "./pool/stupid/n"
-v2*=Created directory "./pool/stupid/n/nowhere"
-d1*=db: 'pool/stupid/n/nowhere/filename_version.tar.gz' added to checksums.db(pool).
-v0*=Deleting files just added to the pool but not used (to avoid use --keepunusednewfiles next time)
-v1*=deleting and forgetting pool/stupid/n/nowhere/filename_version.tar.gz
-d1*=db: 'pool/stupid/n/nowhere/filename_version.tar.gz' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/stupid/n/nowhere
-v2*=removed now empty directory ./pool/stupid/n
EOF
mv conf/distributions.old conf/distributions
testrun - -b . clearvanished 3<<EOF
stderr
stdout
*=Deleting vanished identifier 'getmoreatoms|test|brain'.
EOF
mkdir -p pool/stupid/n/nowhere
dodo test ! -f pool/stupid/n/nowhere/filename_version.tar.gz
cp filename_version.tar.gz pool/stupid/n/nowhere/filename_version.tar.gz
testrun - -b . _detect pool/stupid/n/nowhere/filename_version.tar.gz 3<<EOF
stdout
-d1*=db: 'pool/stupid/n/nowhere/filename_version.tar.gz' added to checksums.db(pool).
-v0*=1 files were added but not used.
-v0*=The next deleteunreferenced call will delete them.
EOF
testout "" -b . dumpunreferenced
cat >results.expected <<EOF
pool/stupid/n/nowhere/filename_version.tar.gz
EOF
dodiff results.expected results
testrun - -b . deleteunreferenced 3<<EOF
stdout
-v1*=deleting and forgetting pool/stupid/n/nowhere/filename_version.tar.gz
-d1*=db: 'pool/stupid/n/nowhere/filename_version.tar.gz' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/stupid/n/nowhere
-v2*=removed now empty directory ./pool/stupid/n
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results
testout "" -b . dumpreferences
# first remove file, then try to remove the package
testrun - -b . _forget pool/ugly/s/simple/simple_1_${FAKEARCHITECTURE}.deb 3<<EOF
stdout
-d1*=db: 'pool/ugly/s/simple/simple_1_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
EOF
testrun - -b . remove test1 simple 3<<EOF
# ???
=Warning: tracking database of test1 missed files for simple_1.
stdout
-v1*=removing 'simple' from 'test1|stupid|${FAKEARCHITECTURE}'...
-v1*=removing 'simple' from 'test1|stupid|source'...
-v1*=removing 'simple' from 'test1|ugly|${FAKEARCHITECTURE}'...
-v1*=removing 'simple' from 'test1|ugly|source'...
-d1*=db: 'simple' removed from packages.db(test1|stupid|${FAKEARCHITECTURE}).
-d1*=db: 'simple' removed from packages.db(test1|stupid|source).
-d1*=db: 'simple' removed from packages.db(test1|ugly|${FAKEARCHITECTURE}).
-d1*=db: 'simple' removed from packages.db(test1|ugly|source).
-v0*=Exporting indices...
-v6*= looking for changes in 'test1|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|stupid|source'...
-v6*=  replacing './dists/test1/stupid/source/Sources' (gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test1/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,bzip2ed)
-v6*= looking for changes in 'test1|ugly|source'...
-v6*=  replacing './dists/test1/ugly/source/Sources' (gzipped,bzip2ed)
EOF
checklog log1 <<EOF
DATESTR remove test1 deb stupid ${FAKEARCHITECTURE} simple 1
DATESTR remove test1 dsc stupid source simple 1
DATESTR remove test1 deb ugly ${FAKEARCHITECTURE} simple 1
DATESTR remove test1 dsc ugly source simple 1
EOF
testrun - -b . remove test2 simple 3<<EOF
*=Unable to forget unknown filekey 'pool/ugly/s/simple/simple_1_${FAKEARCHITECTURE}.deb'.
-v0*=There have been errors!
stdout
-v1=removing 'simple' from 'test2|ugly|${FAKEARCHITECTURE}'...
-d1*=db: 'simple' removed from packages.db(test2|ugly|${FAKEARCHITECTURE}).
-v1=removing 'simple' from 'test2|ugly|source'...
-d1*=db: 'simple' removed from packages.db(test2|ugly|source).
-v0=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test2/ugly/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
-v6*=  replacing './dists/test2/ugly/source/Sources' (uncompressed,gzipped,script: bzip.example,testhook)
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'change'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'change'
-v0=Deleting files no longer referenced...
-v1=deleting and forgetting pool/ugly/s/simple/simple_1_${FAKEARCHITECTURE}.deb
-v1=deleting and forgetting pool/ugly/s/simple/simple_1.dsc
-d1=db: 'pool/ugly/s/simple/simple_1.dsc' removed from checksums.db(pool).
-v1=deleting and forgetting pool/ugly/s/simple/simple_1.tar.gz
-d1=db: 'pool/ugly/s/simple/simple_1.tar.gz' removed from checksums.db(pool).
returns 249
EOF
checklog log2 <<EOF
DATESTR remove test2 deb ugly ${FAKEARCHITECTURE} simple 1
DATESTR remove test2 dsc ugly source simple 1
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results

cat > broken.changes <<EOF
Format: -1.0
Date: yesterday
Source: differently
Version: 0another
Architecture: source ${FAKEARCHITECTURE}
Urgency: super-hyper-duper-important
Maintainer: still me <guess@who>
Description: missing
Changes: missing
Binary: none and nothing
Distribution: test2
Files: 
 `md5sum 4test_b.1-1.dsc| cut -d" " -f 1` `stat -c%s 4test_b.1-1.dsc` a b differently_0another.dsc
 `md5sum 4test_b.1-1_${FAKEARCHITECTURE}.deb| cut -d" " -f 1` `stat -c%s 4test_b.1-1_${FAKEARCHITECTURE}.deb` a b 4test_b.1-1_${FAKEARCHITECTURE}.deb
EOF
#todo: make it work without this..
cp 4test_b.1-1.dsc differently_0another.dsc
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'b.1-1.dsc' does not start with a digit, violating 'should'-directive in policy 5.6.11
=Looks like source but does not start with 'differently_' as I would have guessed!
=I hope you know what you do.
=Warning: Package version 'b.1-1_${FAKEARCHITECTURE}.deb' does not start with a digit, violating 'should'-directive in policy 5.6.11
*=I don't know what to do having a .dsc without a .diff.gz or .tar.gz in 'broken.changes'!
-v0*=There have been errors!
returns 255
EOF
cat >> broken.changes <<EOF
 `md5sum 4test_b.1-1.tar.gz| cut -d" " -f 1` `stat -c%s 4test_b.1-1.tar.gz` a b 4test_b.1-1.tar.gz
EOF
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*=Warning: File '4test_b.1-1.tar.gz' looks like source but does not start with 'differently_'!
=I hope you know what you do.
*='./pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb' has packagename '4test' not listed in the .changes file!
*=To ignore use --ignore=surprisingbinary.
-v0*=There have been errors!
stdout
-v2*=Created directory "./pool/stupid/d"
-v2*=Created directory "./pool/stupid/d/differently"
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/d/differently/differently_0another.dsc' added to checksums.db(pool).
-v0*=Deleting files just added to the pool but not used (to avoid use --keepunusednewfiles next time)
-v1*=deleting and forgetting pool/stupid/d/differently/4test_b.1-1.tar.gz
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/d/differently/differently_0another.dsc
-d1*=db: 'pool/stupid/d/differently/differently_0another.dsc' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/stupid/d/differently
-v2*=removed now empty directory ./pool/stupid/d
returns 255
EOF
testrun - -b . --ignore=surprisingbinary include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*=Warning: File '4test_b.1-1.tar.gz' looks like source but does not start with 'differently_'!
=I hope you know what you do.
*='./pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb' has packagename '4test' not listed in the .changes file!
*=Ignoring as --ignore=surprisingbinary given.
*='./pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb' lists source package '4test', but .changes says it is 'differently'!
-v0*=There have been errors!
stdout
-v2*=Created directory "./pool/stupid/d"
-v2*=Created directory "./pool/stupid/d/differently"
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1.tar.gz' added to checksums.db(pool).
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb' added to checksums.db(pool).
-d1*=db: 'pool/stupid/d/differently/differently_0another.dsc' added to checksums.db(pool).
-v0*=Deleting files just added to the pool but not used (to avoid use --keepunusednewfiles next time)
-v1*=deleting and forgetting pool/stupid/d/differently/4test_b.1-1.tar.gz
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/d/differently/4test_b.1-1_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/d/differently/differently_0another.dsc
-d1*=db: 'pool/stupid/d/differently/differently_0another.dsc' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/stupid/d/differently
-v2*=removed now empty directory ./pool/stupid/d
returns 255
EOF
cat > broken.changes <<EOF
Format: -1.0
Date: yesterday
Source: 4test
Version: 0orso
Architecture: source ${FAKEARCHITECTURE}
Urgency: super-hyper-duper-important
Maintainer: still me <guess@who>
Description: missing
Changes: missing
Binary: 4test
Distribution: test2
Files: 
 `md5sum 4test_b.1-1.dsc| cut -d" " -f 1` `stat -c%s 4test_b.1-1.dsc` a b 4test_0orso.dsc
 `md5sum 4test_b.1-1_${FAKEARCHITECTURE}.deb| cut -d" " -f 1` `stat -c%s 4test_b.1-1_${FAKEARCHITECTURE}.deb` a b 4test_b.1-1_${FAKEARCHITECTURE}.deb
 `md5sum 4test_b.1-1.tar.gz| cut -d" " -f 1` `stat -c%s 4test_b.1-1.tar.gz` a b 4test_b.1-1.tar.gz
EOF
cp 4test_b.1-1.dsc 4test_0orso.dsc
testrun - -b . include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
=Warning: Package version 'b.1-1_${FAKEARCHITECTURE}.deb' does not start with a digit, violating 'should'-directive in policy 5.6.11
*='./pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb' lists source version '1:b.1-1', but .changes says it is '0orso'!
*=To ignore use --ignore=wrongsourceversion.
-v0*=There have been errors!
stdout
-d1*=db: 'pool/stupid/4/4test/4test_0orso.dsc' added to checksums.db(pool).
-v0*=Deleting files just added to the pool but not used (to avoid use --keepunusednewfiles next time)
-v1*=deleting and forgetting pool/stupid/4/4test/4test_0orso.dsc
-d1*=db: 'pool/stupid/4/4test/4test_0orso.dsc' removed from checksums.db(pool).
returns 255
EOF
testrun - -b . --ignore=wrongsourceversion include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*='./pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb' lists source version '1:b.1-1', but .changes says it is '0orso'!
*=Ignoring as --ignore=wrongsourceversion given.
*='4test_0orso.dsc' says it is version '1:b.1-1', while .changes file said it is '0orso'
*=To ignore use --ignore=wrongversion.
-v0*=There have been errors!
stdout
-d1*=db: 'pool/stupid/4/4test/4test_0orso.dsc' added to checksums.db(pool).
-v0*=Deleting files just added to the pool but not used (to avoid use --keepunusednewfiles next time)
-v1*=deleting and forgetting pool/stupid/4/4test/4test_0orso.dsc
-d1*=db: 'pool/stupid/4/4test/4test_0orso.dsc' removed from checksums.db(pool).
returns 255
EOF
checknolog log1
checknolog log2
testrun - -b . --ignore=wrongsourceversion --ignore=wrongversion include test2 broken.changes 3<<EOF
-v0=Data seems not to be signed trying to use directly...
*='./pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb' lists source version '1:b.1-1', but .changes says it is '0orso'!
*=Ignoring as --ignore=wrongsourceversion given.
*='4test_0orso.dsc' says it is version '1:b.1-1', while .changes file said it is '0orso'
*=Ignoring as --ignore=wrongversion given.
stdout
-d1*=db: 'pool/stupid/4/4test/4test_0orso.dsc' added to checksums.db(pool).
-d1*=db: '4test' added to packages.db(test2|stupid|${FAKEARCHITECTURE}).
-d1*=db: '4test' added to packages.db(test2|stupid|source).
-v0*=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*=  replacing './dists/test2/stupid/source/Sources' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'change'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'change'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'old'
EOF
checklog log2 <<EOF
DATESTR add test2 deb stupid ${FAKEARCHITECTURE} 4test 1:b.1-1
DATESTR add test2 dsc stupid source 4test 1:b.1-1
EOF
testrun - -b . remove test2 4test 3<<EOF
stdout
-v1*=removing '4test' from 'test2|stupid|${FAKEARCHITECTURE}'...
-d1*=db: '4test' removed from packages.db(test2|stupid|${FAKEARCHITECTURE}).
-v1*=removing '4test' from 'test2|stupid|source'...
-d1*=db: '4test' removed from packages.db(test2|stupid|source).
-v0*=Exporting indices...
-v6*= looking for changes in 'test2|stupid|${FAKEARCHITECTURE}'...
-v6*=  replacing './dists/test2/stupid/binary-${FAKEARCHITECTURE}/Packages' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|stupid|coal'...
-v6*= looking for changes in 'test2|stupid|source'...
-v6*=  replacing './dists/test2/stupid/source/Sources' (uncompressed,gzipped,script: bzip.example,testhook)
-v6*= looking for changes in 'test2|ugly|${FAKEARCHITECTURE}'...
-v6*= looking for changes in 'test2|ugly|coal'...
-v6*= looking for changes in 'test2|ugly|source'...
-v0*=Deleting files no longer referenced...
-v1*=deleting and forgetting pool/stupid/4/4test/4test_0orso.dsc
-d1*=db: 'pool/stupid/4/4test/4test_0orso.dsc' removed from checksums.db(pool).
*=testhook got 4: './dists/test2' 'stupid/binary-${FAKEARCHITECTURE}/Packages.new' 'stupid/binary-${FAKEARCHITECTURE}/Packages' 'change'
*=testhook got 4: './dists/test2' 'stupid/binary-coal/Packages.new' 'stupid/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'stupid/source/Sources.new' 'stupid/source/Sources' 'change'
*=testhook got 4: './dists/test2' 'ugly/binary-${FAKEARCHITECTURE}/Packages.new' 'ugly/binary-${FAKEARCHITECTURE}/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/binary-coal/Packages.new' 'ugly/binary-coal/Packages' 'old'
*=testhook got 4: './dists/test2' 'ugly/source/Sources.new' 'ugly/source/Sources' 'old'
EOF
checklog log2 <<EOF
DATESTR remove test2 deb stupid ${FAKEARCHITECTURE} 4test 1:b.1-1
DATESTR remove test2 dsc stupid source 4test 1:b.1-1
EOF
testout "" -b . dumpunreferenced
dodiff results.empty results

checknolog log1
checknolog log2

testout "" -b . dumptracks
# TODO: check here for what should be here,
# check the othe stuff, too
#dodiff results.empty results
cat > conf/distributions <<EOF
Codename: X
Architectures: none
Components: test
EOF
testrun - -b . --delete clearvanished 3<<EOF
stderr
-v4*=Strange, 'X|test|none' does not appear in packages.db yet.
stdout
*=Deleting vanished identifier 'test1|stupid|${FAKEARCHITECTURE}'.
*=Deleting vanished identifier 'test1|stupid|source'.
*=Deleting vanished identifier 'test1|ugly|${FAKEARCHITECTURE}'.
*=Deleting vanished identifier 'test1|ugly|source'.
*=Deleting vanished identifier 'test2|stupid|${FAKEARCHITECTURE}'.
*=Deleting vanished identifier 'test2|stupid|coal'.
*=Deleting vanished identifier 'test2|stupid|source'.
*=Deleting vanished identifier 'test2|ugly|${FAKEARCHITECTURE}'.
*=Deleting vanished identifier 'test2|ugly|coal'.
*=Deleting vanished identifier 'test2|ugly|source'.
*=Deleting tracking data for vanished distribution 'test1'.
-v0*=Deleting files no longer referenced...
-v1*=deleting and forgetting pool/stupid/4/4test/4test-addons_b.1-1_all.deb
-d1*=db: 'pool/stupid/4/4test/4test-addons_b.1-1_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/4/4test/4test_b.1-1_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/4/4test/4test_b.1-1.dsc
-d1*=db: 'pool/stupid/4/4test/4test_b.1-1.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/4/4test/4test_b.1-1.tar.gz
-d1*=db: 'pool/stupid/4/4test/4test_b.1-1.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_9.0-A:Z+a:z-0+aA.9zZ_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz
-d1*=db: 'pool/ugly/b/bloat+-0a9z.app/bloat+-0a9z.app_9.0-A:Z+a:z-0+aA.9zZ.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app-addons_0.9-A:Z+a:z-0+aA.9zZ_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz
-d1*=db: 'pool/stupid/b/bloat+-0a9z.app/bloat+-0a9z.app_0.9-A:Z+a:z-0+aA.9zZ.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/s/simple/simple_1_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/s/simple/simple_1.dsc
-d1*=db: 'pool/stupid/s/simple/simple_1.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/s/simple/simple_1.tar.gz
-d1*=db: 'pool/stupid/s/simple/simple_1.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test-addons_1-2_all.deb
-d1*=db: 'pool/stupid/t/test/test-addons_1-2_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/t/test/test_1-2_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1-2.dsc
-d1*=db: 'pool/stupid/t/test/test_1-2.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1.orig.tar.gz
-d1*=db: 'pool/stupid/t/test/test_1.orig.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/test/test_1-2.diff.gz
-d1*=db: 'pool/stupid/t/test/test_1-2.diff.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb-addons_2-3_all.deb
-d1*=db: 'pool/stupid/t/testb/testb-addons_2-3_all.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_2-3_${FAKEARCHITECTURE}.deb
-d1*=db: 'pool/stupid/t/testb/testb_2-3_${FAKEARCHITECTURE}.deb' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_2-3.dsc
-d1*=db: 'pool/stupid/t/testb/testb_2-3.dsc' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_2.orig.tar.gz
-d1*=db: 'pool/stupid/t/testb/testb_2.orig.tar.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/stupid/t/testb/testb_2-3.diff.gz
-d1*=db: 'pool/stupid/t/testb/testb_2-3.diff.gz' removed from checksums.db(pool).
-v1*=deleting and forgetting pool/ugly/s/simple/simple-addons_1_all.deb
-d1*=db: 'pool/ugly/s/simple/simple-addons_1_all.deb' removed from checksums.db(pool).
-v2*=removed now empty directory ./pool/stupid/4/4test
-v2*=removed now empty directory ./pool/stupid/4
-v2*=removed now empty directory ./pool/stupid/b/bloat+-0a9z.app
-v2*=removed now empty directory ./pool/stupid/b
-v2*=removed now empty directory ./pool/stupid/s/simple
-v2*=removed now empty directory ./pool/stupid/s
-v2*=removed now empty directory ./pool/stupid/t/testb
-v2*=removed now empty directory ./pool/stupid/t/test
-v2*=removed now empty directory ./pool/stupid/t
-v2*=removed now empty directory ./pool/stupid
-v2*=removed now empty directory ./pool/ugly/b/bloat+-0a9z.app
-v2*=removed now empty directory ./pool/ugly/b
-v2*=removed now empty directory ./pool/ugly/s/simple
-v2*=removed now empty directory ./pool/ugly/s
-v2*=removed now empty directory ./pool/ugly
-v2*=removed now empty directory ./pool
EOF

checknolog logfile
checknolog log1
checknolog log2

testout "" -b . dumptracks
dodiff results.empty results
testout "" -b . dumpunreferenced
dodiff results.empty results

rm -r dists db conf conf2 logs lists
rm 4test* bloat* simple* test_* test-* testb* differently* filename_version.tar.gz
rm test1 test2 test2.changes broken.changes test.changes fakesuper
rm results results.expected results.log.expected includeerror.rules
dodo test ! -d pool

testsuccess
