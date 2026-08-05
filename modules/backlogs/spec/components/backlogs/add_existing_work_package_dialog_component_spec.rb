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

require "rails_helper"

RSpec.describe Backlogs::AddExistingWorkPackageDialogComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:admin) { create(:admin) }
  current_user { admin }

  let(:project) { create(:project) }
  let(:target) { Backlogs::Target.for(container) }
  let(:expected_url) { add_existing_project_backlogs_work_packages_path(project, target.to_list_params) }

  before do
    render_inline(described_class.new(project:, container:))
  end

  shared_examples "renders the dialog correctly" do
    it "renders the dialog title" do
      expect(page).to have_element(:h1, text: title)
    end

    it "uses correct form action" do
      expect(page).to have_element(:form, action: expected_url)
    end

    it "assigns DIALOG_ID to the dialog element" do
      expect(page).to have_css("dialog##{described_class::DIALOG_ID}")
    end

    it "assigns FORM_ID to the form element" do
      expect(page).to have_css("form##{described_class::FORM_ID}")
    end

    it "links the Cancel button to the dialog" do
      expect(page).to have_css("[data-close-dialog-id='#{described_class::DIALOG_ID}']", text: I18n.t(:button_cancel))
    end

    it "links the Add button to the form as a submit" do
      expect(page).to have_css("button[form='#{described_class::FORM_ID}'][type='submit']", text: I18n.t(:button_add))
    end
  end

  context "when target is a sprint" do
    let(:container) { build_stubbed(:sprint, project:, name: "My Sprint") }
    let(:title) { "Add existing work package" }

    include_examples "renders the dialog correctly"
  end

  context "when target is a backlog bucket" do
    let(:container) { build_stubbed(:backlog_bucket, project:, name: "My Bucket") }
    let(:title) { "Add existing work package" }

    include_examples "renders the dialog correctly"
  end

  context "when target is inbox" do
    let(:container) { Backlogs::Target::Inbox }
    let(:title) { "Add existing work package" }

    include_examples "renders the dialog correctly"
  end
end
