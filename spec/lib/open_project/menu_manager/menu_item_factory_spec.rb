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

describe Redmine::MenuManager::MenuItemFactory do
  let(:klass) { Redmine::MenuManager::MenuItemFactory }

  describe "build" do
    describe "WITH a block for a label" do
      block = Proc.new{ |x| "" }

      it "should return a menu item" do
        klass.build(block).is_a?(Redmine::MenuManager::MenuItem).should be_true
      end
    end
  end
end
