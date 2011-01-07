require File.dirname(__FILE__) + '/../spec_helper'

describe Redmine::DefaultData::Loader do

  describe :load do
    before :each do
      clear_access_control_permissions
      create_non_member_role
      create_anonymous_role
      Redmine::DefaultData::Loader.load
    end

    #describes only the results of load in the db
    it {Role.find_by_name(I18n.t(:default_role_manager)).attributes["type"].should eql "Role"}
    it {Role.find_by_name(I18n.t(:default_role_developper)).attributes["type"].should eql "Role"} #[sic]
    it {Role.find_by_name(I18n.t(:default_role_reporter)).attributes["type"].should eql "Role"}
  end

end