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

RSpec.describe "Create repository", :js do
  let(:current_user) { create (:admin) }
  let(:project) { create(:project) }
  let(:enabled_scms) { %w[git] }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)
    allow(Setting).to receive(:repository_checkout_data).and_return(checkout_data)

    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with("scm").and_return(config)
  end

  context "managed repositories" do
    include_context "with tmpdir"
    let(:config) do
      {
        git: { manages: File.join(tmpdir, "git") }
      }
    end
    let(:checkout_data) do
      { "git" => { "enabled" => "1", "base_url" => "http://localhost/git/" } }
    end

    let!(:repository) do
      repo = build(:repository_git, scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)
      repo.save!
      perform_enqueued_jobs

      repo
    end

    it "toggles checkout instructions" do
      visit project_repository_path(project)

      expect(page).to have_css("#repository--checkout-instructions")

      button = find_by_id("repository--checkout-instructions-toggle")
      button.click

      expect(page).to have_no_css("#repository--checkout-instructions")
    end
  end
end
