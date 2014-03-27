#-- copyright
# OpenProject Global Roles Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Redmine::AccessControl do
  before(:each) do
    stash_access_control_permissions

    Redmine::AccessControl.map do |map|
      map.permission :proj0, {:dont => :care}, :require => :member
      map.permission :global0, {:dont => :care}, :global => true
      map.permission :proj1, {:dont => :care}

      map.project_module :global_module do |mod|
        mod.permission :global1, {:dont => :care}, :global => true
      end

      map.project_module :project_module do |mod|
        mod.permission :proj2, {:dont => :care}
      end

      map.project_module :mixed_module do |mod|
        mod.permission :proj3, {:dont => :care}
        mod.permission :global2, {:dont => :care}, :global => true
      end
    end
  end

  after(:each) do
    restore_access_control_permissions
  end

  describe "class methods" do
    describe :global_permissions do
      it {Redmine::AccessControl.global_permissions.should have(3).items}
      it {Redmine::AccessControl.global_permissions.collect(&:name).should include(:global0)}
      it {Redmine::AccessControl.global_permissions.collect(&:name).should include(:global1)}
      it {Redmine::AccessControl.global_permissions.collect(&:name).should include(:global2)}
    end

    describe :available_project_modules do
      it {Redmine::AccessControl.available_project_modules.include?(:global_module).should be_false }
      it {Redmine::AccessControl.available_project_modules.include?(:global_module).should be_false }
      it {Redmine::AccessControl.available_project_modules.include?(:mixed_module).should be_true }
    end
  end
end
