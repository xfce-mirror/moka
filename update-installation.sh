#!/bin/sh

rake build && su -c 'gem install --local pkg/moka-0.3.0.gem --no-ri --no-rdoc'
