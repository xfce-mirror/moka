#!/bin/sh

git pull --rebase && rake build &&  su -c 'gem install pkg/moka-0.1.0.gem'
