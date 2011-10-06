#!/bin/sh

rake build && su -c 'gem install --local pkg/moka-0.1.0.gem --no-ri --no-rdoc'
