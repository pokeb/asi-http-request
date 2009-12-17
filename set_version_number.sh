#!/bin/sh
versionString=`/opt/local/bin/git describe --tags`
version="`echo $versionString | sed -E 's/(v([0-9]+)\.([0-9]+))(.*)/\1/g'`"
commitNum="`echo $versionString | sed -E 's/(v([0-9]+)\.([0-9]+))\-([0-9]*)(.*)/\4/g'`"
date=`date "+%Y-%m-%d"`
displayVersion="${version}-`expr $commitNum + 1` ${date}"

sed -i "" "s/NSString \*ASIHTTPRequestVersion = @\"\(.*\)/NSString *ASIHTTPRequestVersion = @\"$displayVersion\";/g" Classes/ASIHTTPRequest.m
