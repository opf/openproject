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

require_relative "../../support/pages/my/page"

RSpec.describe "Work package watched widget on My page", :js do
  shared_let(:user) { create(:user) }
  shared_let(:non_member) { create(:non_member, permissions: [:view_work_packages]) }
  shared_let(:project) { create(:project, public: true) }
  shared_let(:work_package) do
    create(:work_package,
           project:,
           subject: "Visible work package for non member",
           author: user,
           responsible: user)
  end

  let(:my_page) do
    Pages::My::Page.new
  end

  before do
    login_as user
    work_package.add_watcher(user)

    my_page.visit!
  end

  it "can add the watcher widget without being member anywhere (Regression #55838)" do
    my_page.add_widget(1, 1, :within, "Work packages watched by me")

    expect(page).to have_text(work_package.subject)
  end
end
