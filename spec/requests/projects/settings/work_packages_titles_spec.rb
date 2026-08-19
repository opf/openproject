# frozen_string_literal: true

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

RSpec.describe "Projects::Settings::WorkPackages page titles", type: :rails_request do
  shared_let(:project) { create(:project, name: "My Project") }
  shared_let(:user) do
    create(:user,
           member_with_permissions: {
             project => %i[edit_project manage_types manage_categories select_custom_fields]
           })
  end

  before { login_as user }

  def rendered_title
    response.body[%r{<title>(.*?)</title>}m, 1]
  end

  it "names the active tab first, then the breadcrumb outwards" do
    get project_settings_work_packages_types_path(project)

    expect(rendered_title).to eq("Types | Work packages | Project settings | My Project | OpenProject")
  end

  it "varies the first segment per tab" do
    get project_settings_work_packages_categories_path(project)

    expect(rendered_title).to eq("Categories | Work packages | Project settings | My Project | OpenProject")
  end

  # The internal comments nav label carries an Enterprise upsell octicon.
  it "keeps the upsell icon out of the title" do
    get project_settings_work_packages_internal_comments_path(project)

    expect(rendered_title).to eq("Internal Comments | Work packages | Project settings | My Project | OpenProject")
  end
end
