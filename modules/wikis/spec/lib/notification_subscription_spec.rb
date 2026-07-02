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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require_module_spec_helper

RSpec.describe "Subscriptions to OpenProject::Notification" do # rubocop:disable RSpec/DescribeClass
  let(:project) { create(:project) }
  let(:internal_provider_enabled) { true }
  let(:internal_provider) { create(:internal_wiki_provider, enabled: internal_provider_enabled) }
  let(:enabled_module) { EnabledModule.new(project:, name: "wiki") }

  # The event is triggered by saving the EnabledModule
  describe "OpenProject::Events::MODULE_ENABLED" do
    before { internal_provider }

    context "when internal wikis are enabled" do
      it "create an internal wiki for the project" do
        expect { enabled_module.save }.to change(Wiki, :count).by(1)
      end

      it "the wiki start page is named Wiki" do
        enabled_module.save
        created_wiki = Wiki.last
        expect(created_wiki.start_page).to eq("Wiki")
      end

      it "does not create a wiki if one already exists" do
        Wiki.create(project:, start_page: "I wiki, therefore I am")

        expect { enabled_module.save }.not_to change(Wiki, :count)
      end
    end

    context "when internal wikis are disabled" do
      let(:internal_provider_enabled) { false }

      it "does not create an internal wiki for the project" do
        expect { enabled_module.save }.not_to change(Wiki, :count)
      end
    end
  end

  # This event is fired when the module is removed from the project.
  # It is emitted by the Project model
  describe "OpenProject::Events::MODULE_DISABLED" do
    let(:project) { create(:project, enabled_modules: ["wiki"]) }

    context "when internal wikis are enabled" do
      it "makes the wiki invisible" do
        skip "Magic seems to handle this"
      end
    end

    context "when internal wikis are disabled" do
      it "ensures that no internal wiki is visible for the project"
    end
  end
end
