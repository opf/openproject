#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2010-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../spec_helper'

describe Redmine::DefaultData::Loader do

  describe :load do
    before :each do
      stash_access_control_permissions
      create_non_member_role
      create_anonymous_role
      Redmine::DefaultData::Loader.load
    end

    after(:each) do
      restore_access_control_permissions
    end

    #describes only the results of load in the db
    it {Role.find_by_name(I18n.t(:default_role_manager)).attributes["type"].should eql "Role"}

    if Redmine::VERSION::MAJOR < 1
      it {Role.find_by_name(I18n.t(:default_role_developper)).attributes["type"].should eql "Role"} #[sic]
    else
      it {Role.find_by_name(I18n.t(:default_role_developer)).attributes["type"].should eql "Role"} #[sic]
    end

    it {Role.find_by_name(I18n.t(:default_role_reporter)).attributes["type"].should eql "Role"}
  end

end
