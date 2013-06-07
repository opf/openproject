#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

#-- encoding: UTF-8
$: << File.join(File.dirname(__FILE__), '..', 'lib')
$: << File.dirname(__FILE__)

require 'rubygems'
require 'test/unit'
require 'active_record'
require 'shoulda'
require 'mocha/setup'
require 'vestal_versions'
require 'schema'
begin; require 'redgreen'; rescue LoadError; end
