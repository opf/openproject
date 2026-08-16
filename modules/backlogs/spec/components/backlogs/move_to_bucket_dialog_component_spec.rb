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
  let(:first) { create(:work_package, project:) }
  let(:second) { create(:work_package, project:) }
  let(:work_packages) { [second, first] }
  let(:move_path) { Rails.application.routes.url_helpers.move_project_backlogs_work_packages_path(project) }
  let(:buckets) { [create(:backlog_bucket, project:, name: "Passed Bucket")] }

  def render_component
    render_inline(described_class.new(work_packages:, buckets:, move_action: move_path))
  end

  it "renders the dialog with the correct title" do
    render_component

    expect(page).to have_text(I18n.t(:"backlogs.move_to_bucket_dialog_component.title"))
  end

  it "renders an ordered collection form targeting the move path via PUT", :aggregate_failures do
    render_component

    expect(page).to have_text(I18n.t(:label_x_work_packages, count: 2))
    expect(page.all("input[name='ids[]']", visible: :all).map(&:value))
      .to eq([second.id.to_s, first.id.to_s])
    expect(page).to have_element(:form, action: move_path, method: "post")
    expect(page).to have_css("form[action='#{move_path}'] input[name='_method'][value='put']", visible: :all)
    expect(page).to have_css(
      "input[name='list_type'][value='#{Backlogs::Target::BucketId.new(nil).list_type}']",
      visible: :all
    )
  end

  # The count sits in its own paragraph above the select, so it only reaches a
  # screen reader as the field's context through this reference.
  it "describes the bucket select by the selected-count label" do
    render_component

    label = page.find_css("p##{described_class::SELECTION_LABEL_ID}").first
    expect(label.text).to include(I18n.t(:label_x_work_packages, count: 2))
    expect(page).to have_css(
      "select[name='list_id'][aria-describedby~='#{described_class::SELECTION_LABEL_ID}']",
      visible: :all
    )
  end

  it "renders Cancel and Move buttons" do
    render_component

    expect(page).to have_button(I18n.t(:button_cancel))
    expect(page).to have_button(I18n.t(:button_move))
  end

  context "when other bucket records exist" do
    let!(:omitted_bucket) { create(:backlog_bucket, project:, name: "Omitted Bucket") }

    it "renders only the destinations supplied by the controller" do
      render_component

      expect(page).to have_css("option[value='#{buckets.first.id}']", text: "Passed Bucket")
      expect(page).to have_no_css("option[value='#{omitted_bucket.id}']")
    end
  end
end
