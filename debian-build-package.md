## Turn the gem into a (dirty) debian package
* Get a running Debian instance with the OS version you want to buidl the package for.
* Change version in version.txt to new value
* CD into root folder of this repository

```
apt-get install ruby-dev

gem install fpm bundler rspec
bundle install
rake build

GEM_HOME=opt/xtrabackup-rb gem install --no-ri --no-rdoc pkg/xtrabackup-rb-$(cat version.txt).gem


mkdir -p usr/bin
mkdir -p opt

cat <<EOF >usr/bin/xtrabackup-rb
#!/bin/sh
set -e
export GEM_HOME="/opt/xtrabackup-rb"
exec \${GEM_HOME}/bin/xtrabackup-rb \$@
EOF

chmod +x usr/bin/xtrabackup-rb

fpm -s dir -t deb -p pkg -a all -n xtrabackup-rb -v $(cat version.txt) usr opt

rm -r opt/ usr/
ls pkg/*.deb
```
