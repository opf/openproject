require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Redmine::AccessControl do
  before(:each) do
    Redmine::AccessControl.permissions.clear #this line is required although it should not be
    # otherwise permissions from previous tests are kept

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