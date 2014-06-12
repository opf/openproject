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
    it {expect(Role.find_by_name(I18n.t(:default_role_manager)).attributes["type"]).to eql "Role"}

    if Redmine::VERSION::MAJOR < 1
      it {expect(Role.find_by_name(I18n.t(:default_role_developper)).attributes["type"]).to eql "Role"} #[sic]
    else
      it {expect(Role.find_by_name(I18n.t(:default_role_developer)).attributes["type"]).to eql "Role"} #[sic]
    end

    it {expect(Role.find_by_name(I18n.t(:default_role_reporter)).attributes["type"]).to eql "Role"}
  end

end
