#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "Work package show page", :selenium do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:work_package) do
    build(:work_package,
          project:,
          assigned_to: user,
          responsible: user)
  end

  before do
    login_as(user)
    work_package.save!
  end

  it "all different angular based work package views", :js do
    wp_page = Pages::FullWorkPackage.new(work_package)

    wp_page.visit!

    wp_page.expect_attributes type: work_package.type.name.upcase,
                              status: work_package.status.name,
                              priority: work_package.priority.name,
                              assignee: work_package.assigned_to.name,
                              responsible: work_package.responsible.name
  end
end
