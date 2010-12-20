require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Redmine::AccessControl do
  describe "WITH AccessControl.map" do
    before (:each) do
      Redmine::AccessControl.map do |map|
        map.permission :non_glob1, {:dont => :care}, :require => :member
        map.permission :glob, {:dont => :care}, :global => true
        map.permission :non_glob2, {:dont => :care}
      end
    end

    describe :global_permissions do
      subject {Redmine::AccessControl.global_permissions}

      it {should have(1).items}
      it {Redmine::AccessControl.global_permissions[0].name.should eql(:glob)}
    end
  end
end