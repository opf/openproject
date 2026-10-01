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

RSpec.describe "project export", :js do
  shared_let(:project) { create(:project, :with_internal_wiki).reload }

  let(:wiki_page1) do
    build(:wiki_page, title: "Some title!")
  end

  let(:current_user) { create(:admin) }

  before do
    @download_list = DownloadList.new

    login_as(current_user)

    project.wiki.pages << wiki_page1

    project.wiki.save!

    visit project_wiki_path(project, "Some title!")
  end

  after do
    DownloadList.clear
  end

  subject { @download_list.refresh_from(page).latest_downloaded_content } # rubocop:disable RSpec/InstanceVariable

  it "exports the wiki" do
    page.find_test_selector("wiki-more-dropdown-menu").click
    page.find_test_selector("export-button").click

    page.find_test_selector("markdown-export").click

    wait_for_network_idle

    begin
      perform_enqueued_jobs
    rescue StandardError
      # nothing
    end

    result = expect(subject)
    result.to have_text(wiki_page1.title)
  end
end
