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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe WorkPackages::Progress::WorkBased::ModalBodyComponent, "with read only remaining work", type: :component do
  let(:remaining_work_read_only) { true }
  let(:project) do
    create(:project, logged_time_reduces_remaining_work: true, remaining_work_read_only:)
  end
  let(:user) { create(:user, member_with_permissions: { project => %i[view_work_packages edit_work_packages] }) }
  let(:work_package) { create(:work_package, project:, estimated_hours: 5.0, remaining_hours: 3.0, done_ratio: 40) }

  current_user { user }

  subject(:rendered_component) { render_inline(described_class.new(work_package)) }

  it "renders remaining work and % complete disabled" do
    expect(rendered_component).to have_field("work_package[remaining_hours]", disabled: true)
    expect(rendered_component).to have_field("work_package[done_ratio]", disabled: true)
  end

  it "explains why remaining work and % complete are disabled" do
    expect(rendered_component).to have_text(I18n.t("work_package.progress.read_only_hint"), count: 2)
  end

  it "keeps work editable" do
    expect(rendered_component).to have_field("work_package[estimated_hours]", disabled: false)
  end

  context "when remaining work is not read only" do
    let(:remaining_work_read_only) { false }

    it "renders remaining work and % complete editable" do
      expect(rendered_component).to have_field("work_package[remaining_hours]", disabled: false)
      expect(rendered_component).to have_field("work_package[done_ratio]", disabled: false)
    end
  end
end
