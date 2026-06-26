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

RSpec.describe Backlogs::WorkPackageCardListItemLoadingComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:type_feature) { create(:type_feature) }
  shared_let(:default_status) { create(:default_status) }
  shared_let(:user) { create(:admin) }
  current_user { user }

  shared_let(:project) { create(:project, types: [type_feature]) }
  shared_let(:sprint) { create(:sprint, project:, name: "Sprint 1") }
  shared_let(:persisted_work_package) do
    create(:work_package, project:, type: type_feature, status: default_status, subject: "Card subject", sprint:)
  end

  # Loaded through the scope so the card_hash projection is available, mirroring
  # how the list feeds its rows in production.
  let(:work_package) { WorkPackage.where(id: persisted_work_package.id).with_card_hash.first }

  subject(:rendered_component) do
    render_inline(described_class.new(work_package:, project:, container: sprint, current_user: user))
  end

  it "renders a lazy turbo-frame targeting the card" do
    expect(rendered_component).to have_css(
      "turbo-frame#work_package_#{work_package.id}_card[loading='lazy']"
    )
  end

  it "points the frame at the card path with the card_hash as the version" do
    expect(rendered_component).to have_css(
      "turbo-frame[src='#{project_backlogs_work_package_card_path(project, work_package, version: work_package.card_hash)}']"
    )
  end

  it "renders a skeleton placeholder while the card loads" do
    expect(rendered_component).to have_css("turbo-frame .Skeleton, turbo-frame [class*='Skeleton']")
  end

  it "does not render the card content itself" do
    expect(rendered_component).to have_no_text("Card subject")
  end
end
