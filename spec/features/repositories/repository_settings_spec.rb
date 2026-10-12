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
require "features/repositories/repository_settings_page"

RSpec.describe "Repository Settings", :js do
  let(:current_user) { create (:admin) }
  let(:project) { create(:project) }
  let(:settings_page) { RepositorySettingsPage.new(project) }

  # Allow to override configuration values to determine
  # whether to activate managed repositories
  let(:enabled_scms) { %w[subversion git] }
  let(:config) { nil }

  before do
    allow(User).to receive(:current).and_return current_user
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)

    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with("scm").and_return(config)

    allow(project).to receive(:repository).and_return(repository)
    settings_page.visit_repository_settings
  end

  shared_examples "manages the repository" do |type|
    it "displays the repository" do
      expect(page).to have_select("scm_vendor", disabled: true)
      expect(page).to have_css("#attributes-group--content-#{type}", visible: :visible)
    end

    it "deletes the repository" do
      expect(Repository.exists?(repository.id)).to be true

      SeleniumHubWaiter.wait
      if type == "managed"
        find("a.icon-delete", text: I18n.t(:button_delete)).click

        expect(page).to have_css("danger-dialog-form-helper:defined", wait: 20)
        within("#destroy-repository-dialog") do
          confirmation_label = "I understand that this deletion cannot be reversed."
          confirmation = find_field(confirmation_label)
          page.execute_script("arguments[0].click()", confirmation) unless confirmation.checked?

          delete_button = nil
          page.document.synchronize(10) do
            confirmation = find_field(confirmation_label, wait: 0)
            delete_button = find_button(I18n.t(:button_delete_permanently), disabled: false, wait: 0)
            raise Capybara::ElementNotFound unless confirmation.checked?
          end

          page.execute_script("arguments[0].click()", delete_button)
        end
      else
        find("a.icon-remove", text: I18n.t(:button_remove)).click

        SeleniumHubWaiter.wait
        within("#destroy-repository-dialog") do
          click_on I18n.t(:button_remove)
        end
      end

      vendor = find('select[name="scm_vendor"]')
      expect(vendor).not_to be_nil
      expect(vendor.value).to be_empty

      selected = vendor.find("option[selected]")
      expect(selected.text).to eq("--- Please select ---")
      expect(selected[:disabled]).to be_truthy
      expect(selected[:selected]).to be_truthy

      # Project should have no repository
      expect(Repository.exists?(repository.id)).to be false
    end
  end

  shared_examples "manages the repository with" do |name, type, _repository_type, _project_name|
    let(:repository) do
      create(:"repository_#{name}",
             scm_type: type,
             project:)
    end

    it_behaves_like "manages the repository", type
  end

  it_behaves_like "manages the repository with", "subversion", "existing", "Subversion - Repository", "project"
  it_behaves_like "manages the repository with", "git", "local", "Git - Repository", "project"

  context "with managed repositories" do
    context "with local repositories" do
      include_context "with tmpdir"
      let(:config) do
        {
          subversion: { manages: File.join(tmpdir, "svn") },
          git: { manages: File.join(tmpdir, "git") }
        }
      end

      let(:repository) do
        repo = Repository.build(
          project,
          managed_vendor,
          # Need to pass AC params here manually to simulate a regular repository build
          ActionController::Parameters.new({}),
          :managed
        )

        repo.save!
        repo
      end

      context "with Subversion" do
        let(:managed_vendor) { :subversion }

        it_behaves_like "manages the repository", "managed"
      end

      context "with Git" do
        let(:managed_vendor) { :git }

        it_behaves_like "manages the repository", "managed"
      end
    end

    context "with a remote repository", :webmock do
      let(:url) { "http://myreposerver.example.com/api/" }
      let(:config) do
        {
          git: { manages: url }
        }
      end
      let(:managed_vendor) { :git }
      let(:repository) do
        repo = Repository.build(
          project,
          managed_vendor,
          # Need to pass AC params here manually to simulate a regular repository build
          ActionController::Parameters.new({}),
          :managed
        )

        stub_request(:post, url)
          .to_return(status: 200,
                     body: { success: true, url: "file:///foo/bar" }.to_json)

        repo.save!
        repo
      end

      it_behaves_like "manages the repository", "managed"
    end
  end

  describe "update repositories" do
    let(:repository) do
      create(:repository_subversion,
             scm_type: :existing,
             project:)
    end

    it "can set login and password" do
      fill_in("repository[login]", with: "foobar")
      fill_in("repository-password-placeholder", with: "password")

      click_button(I18n.t(:button_save))
      expect(page).to have_css('[name="repository[login]"][value="foobar"]')
      expect_flash(message: I18n.t("repositories.update_settings_successful"))
    end
  end
end
