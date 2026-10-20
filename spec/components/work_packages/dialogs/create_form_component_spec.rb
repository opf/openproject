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

require "rails_helper"

RSpec.describe WorkPackages::Dialogs::CreateFormComponent, type: :component do
  subject(:render_component) { render_inline(described_class.new(work_package:, project: work_package.project)) }

  let(:work_package) { create(:work_package) }
  let(:user) { create(:admin) }

  before do
    User.current = user
  end

  it "enables the subject input" do
    render_component
    expect(page.find('input[name="work_package[subject]"]')).not_to be_disabled
  end

  context "when the user has no edit permissions" do
    let(:user) { User.anonymous }

    it "disables the subject input" do
      render_component
      expect(page.find('input[name="work_package[subject]"]')).to be_disabled
    end
  end

  context "when the work package subject is generated automatically" do
    let(:work_package) { create(:work_package, type:) }
    let(:type) { create(:type, patterns: { subject: { enabled: true, blueprint: "My Subject" } }) }

    it "disables the subject input" do
      render_component
      expect(page.find('input[name="work_package[subject]"]')).to be_disabled
    end
  end
end
