#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe "default query", type: :model do
  let(:query) { Query.new_default }

  describe "highlighting mode" do
    context " with highlighting mode setting", with_ee: %i[conditional_highlighting] do
      describe "not set" do
        it "is inline" do
          expect(query.highlighting_mode).to eq :inline
        end
      end

      describe "set to inline", with_settings: { work_package_list_default_highlighting_mode: "inline" } do
        it "is inline" do
          expect(query.highlighting_mode).to eq :inline
        end
      end

      describe "set to none", with_settings: { work_package_list_default_highlighting_mode: "none" } do
        it "is none" do
          expect(query.highlighting_mode).to eq :none
        end
      end

      describe "set to status", with_settings: { work_package_list_default_highlighting_mode: "status" } do
        it "is status" do
          expect(query.highlighting_mode).to eq :status
        end
      end

      describe "set to priority", with_settings: { work_package_list_default_highlighting_mode: "priority" } do
        it "is priority" do
          expect(query.highlighting_mode).to eq :priority
        end
      end

      describe "set to invalid value", with_settings: { work_package_list_default_highlighting_mode: "fubar" } do
        it "is inline" do
          expect(query.highlighting_mode).to eq :inline
        end
      end
    end
  end
end
