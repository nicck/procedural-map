#!/usr/bin/env bash

bundle install --path=.bundle

time bundle exec ruby map.rb

shards install

time crystal run mar.cr
