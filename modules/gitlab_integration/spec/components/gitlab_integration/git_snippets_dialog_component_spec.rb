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

RSpec.describe GitlabIntegration::GitSnippetsDialogComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:work_package_subject) { "Stormtrooper Training" }
  let(:work_package_type) { create(:type, name: "Responsibility") }
  let(:work_package) { create(:work_package, subject: work_package_subject, type: work_package_type) }

  before do
    render_inline described_class.new(work_package)
  end

  it "renders successfully" do
    expect(page).to have_text "Git quick snippets"
    expect(page).to have_test_selector("gitlab-snippets-branch-name")
    expect(page).to have_test_selector("gitlab-snippets-commit-message")
    expect(page).to have_test_selector("gitlab-snippets-create-branch-command")
  end

  describe "branch name" do
    it "renders the expected branch name" do
      expect(page).to have_test_selector("gitlab-snippets-branch-name",
                                         value: "responsibility/#{work_package.id}-stormtrooper-training")
    end

    context "if the work package type contains non-word characters" do
      let(:work_package_type) { create(:type, name: "Difficult Task") }

      it "renders the expected branch name" do
        expect(page).to have_test_selector("gitlab-snippets-branch-name",
                                           value: "difficult-task/#{work_package.id}-stormtrooper-training")
      end
    end

    context "if the work package subject contains non-word characters" do
      let(:work_package_subject) { "Stormtroopers' Training & Drill" }

      it "replaces any non-word characters" do
        expect(page).to have_test_selector("gitlab-snippets-branch-name",
                                           value: "responsibility/#{work_package.id}-stormtroopers-training-and-drill")
      end
    end

    context "if semantic identifiers are configured", with_settings: { work_packages_identifier: "semantic" } do
      it "renders the expected branch name" do
        wp_id = work_package.identifier.downcase
        expect(page).to have_test_selector("gitlab-snippets-branch-name",
                                           value: "responsibility/#{wp_id}-stormtrooper-training")
      end
    end
  end

  describe "commit message name" do
    it "renders the expected commit message" do
      expect(page).to have_test_selector("gitlab-snippets-commit-message",
                                         text: "OP##{work_package.id} Stormtrooper Training")
      expect(page).to have_test_selector("gitlab-snippets-commit-message",
                                         text: "http://localhost:3000/wp/#{work_package.id}")
    end

    context "if the work package subject contains non-word characters" do
      let(:work_package_subject) { "Stormtroopers' Training & Drill" }

      it "renders the expected commit message" do
        expect(page).to have_test_selector("gitlab-snippets-commit-message",
                                           text: "OP##{work_package.id} Stormtroopers' Training & Drill")
        expect(page).to have_test_selector("gitlab-snippets-commit-message",
                                           text: "http://localhost:3000/wp/#{work_package.id}")
      end
    end

    context "if semantic identifiers are configured", with_settings: { work_packages_identifier: "semantic" } do
      it "renders the expected commit message" do
        wp_id = work_package.identifier
        expect(page).to have_test_selector("gitlab-snippets-commit-message",
                                           text: "OP##{wp_id} Stormtrooper Training")
        expect(page).to have_test_selector("gitlab-snippets-commit-message",
                                           text: "http://localhost:3000/wp/#{wp_id}")
      end
    end
  end

  # rubocop:disable-next Style/StringConcatenation
  describe "create branch command" do
    it "renders the expected CLI command" do
      command_text = "git switch -c responsibility/#{work_package.id}-stormtrooper-training && \\" +
                     "  git commit --allow-empty \\" +
                     "  -m 'OP##{work_package.id} Stormtrooper Training' \\" +
                     "  -m 'http://localhost:3000/wp/#{work_package.id}'"

      expect(page).to have_test_selector("gitlab-snippets-create-branch-command", text: command_text)
    end

    context "if the work package type contains non-word characters" do
      let(:work_package_type) { create(:type, name: "Difficult Task") }

      it "renders the expected CLI command" do
        command_text = "git switch -c difficult-task/#{work_package.id}-stormtrooper-training && \\" +
                       "  git commit --allow-empty \\" +
                       "  -m 'OP##{work_package.id} Stormtrooper Training' \\" +
                       "  -m 'http://localhost:3000/wp/#{work_package.id}'"

        expect(page).to have_test_selector("gitlab-snippets-create-branch-command", text: command_text)
      end
    end

    context "if the work package subject contains non-word characters" do
      let(:work_package_subject) { "Stormtroopers' Training & Drill" }

      it "renders the expected CLI command" do
        command_text = "git switch -c responsibility/#{work_package.id}-stormtroopers-training-and-drill && \\" +
                       "  git commit --allow-empty \\" +
                       "  -m 'OP##{work_package.id} Stormtroopers\\' Training & Drill' \\" +
                       "  -m 'http://localhost:3000/wp/#{work_package.id}'"

        expect(page).to have_test_selector("gitlab-snippets-create-branch-command", text: command_text)
      end
    end

    context "if semantic identifiers are configured", with_settings: { work_packages_identifier: "semantic" } do
      it "renders the expected CLI command" do
        wp_id = work_package.identifier
        command_text = "git switch -c responsibility/#{wp_id.downcase}-stormtrooper-training && \\" +
                       "  git commit --allow-empty \\" +
                       "  -m 'OP##{wp_id} Stormtrooper Training' \\" +
                       "  -m 'http://localhost:3000/wp/#{wp_id}'"

        expect(page).to have_test_selector("gitlab-snippets-create-branch-command", text: command_text)
      end
    end
  end
end
