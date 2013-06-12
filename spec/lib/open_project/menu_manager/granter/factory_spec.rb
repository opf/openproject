#-- encoding: UTF-8
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
require 'spec_helper'

describe Redmine::MenuManager::Granter::Factory do
  let(:klass) { Redmine::MenuManager::Granter::Factory }

  describe "build" do
    it "should return whatever is provided as options[:if] if it has a call method" do
      block = Proc.new { true }

      options = { :if => block }

      klass.build({}, options).should == block
    end

    it "should return the neutral granter if options[:if] is empty" do
      options = {}
      url = {}

      klass.build(url, options).should == Redmine::MenuManager::Granter::Always
    end
  end
end
