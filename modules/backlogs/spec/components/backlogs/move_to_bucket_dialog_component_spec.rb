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

RSpec.describe Backlogs::MoveToBucketDialogComponent, type: :component do
  shared_let(:admin) { create(:admin) }
  current_user { admin }

  let(:project) { create(:project) }
  let(:work_package) { create(:work_package, project:) }
  let(:move_path) { Rails.application.routes.url_helpers.move_project_backlogs_work_package_path(project, work_package) }

  def render_component
    render_inline(described_class.new(work_package:, project:, move_action: move_path))
  end

  it "renders the dialog with the correct title" do
    render_component

    expect(page).to have_text(I18n.t(:"backlogs.move_to_bucket_dialog_component.title"))
  end

  it "renders a form targeting the move path via PUT" do
    render_component

    expect(page).to have_element(:form, action: move_path, method: "post")
    expect(page).to have_element(:input, name: "_method", value: "put", visible: :all)
  end

  context "when params[:all] is true" do
    let(:move_path) do
      Rails.application.routes.url_helpers.move_project_backlogs_work_package_path(project, work_package, all: "true")
    end

    it "submits the move form with the all query preserved" do
      render_component

      expect(page).to have_element(:form, action: /all=true/)
    end
  end

  it "renders Cancel and Move buttons" do
    render_component

    expect(page).to have_button(I18n.t(:button_cancel))
    expect(page).to have_button(I18n.t(:button_move))
  end

  context "when buckets exist" do
    let!(:bucket_a) { create(:backlog_bucket, project:, name: "Alpha") }
    let!(:bucket_b) { create(:backlog_bucket, project:, name: "Beta") }

    it "lists them as select options with backlog_bucket: prefix values" do
      render_component

      expect(page).to have_element(:option, value: "backlog_bucket:#{bucket_a.id}", text: "Alpha")
      expect(page).to have_element(:option, value: "backlog_bucket:#{bucket_b.id}", text: "Beta")
    end
  end

  context "when a bucket belongs to a different project" do
    let!(:other_bucket) { create(:backlog_bucket, project: create(:project), name: "Other") }

    it "does not list buckets from other projects" do
      render_component

      expect(page).to have_no_css(:option, text: "Other")
    end
  end

  context "when the work package is already in a bucket" do
    let!(:current_bucket) { create(:backlog_bucket, project:, name: "Current") }
    let!(:target_bucket) { create(:backlog_bucket, project:, name: "Target") }
    let(:work_package) { create(:work_package, project:, backlog_bucket: current_bucket) }

    it "excludes the current bucket from the options" do
      render_component

      expect(page).to have_no_css(:option, text: "Current")
      expect(page).to have_element(:option, value: "backlog_bucket:#{target_bucket.id}", text: "Target")
    end
  end
end
