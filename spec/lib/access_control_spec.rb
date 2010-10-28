require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Redmine::AccessControl do

  describe "WITH permission mocks" do
  before (:each) do
    # mapper = mock_model Redmine::AccessControl::Mapper
    #     @glob_permission = mock_model Redmine::AccessControl::Permission
    #     @glob_permission.stub!(:global?).and_return(true)
    #     @non_glob_permission1 = mock_model Redmine::AccessControl::Permission
    #     @non_glob_permission1.stub!(:global?).and_return(false)
    #     @non_glob_permission2 = mock_model Redmine::AccessControl::Permission
    #     @non_glob_permission2.stub!(:global?).and_return(false)
    #     Redmine::AccessControl::Mapper.stub!(:new).and_return(mapper)
    #     mapper.stub!(:mapped_permissions).and_return([@non_glob_permission1, @glob_permission, @non_glob_permission2])
    #     Redmine::AccessControl.map {}
  end

  describe :global_permissions do
    #it {Redmine::AccessControl.global_permissions.should eql([@glob_permission])}
  end
end

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