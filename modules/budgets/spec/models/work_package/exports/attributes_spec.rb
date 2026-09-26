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

RSpec.describe WorkPackage::Exports::Attributes, "budget" do
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking budgets]) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:exporter) { Class.new { include WorkPackage::Exports::Attributes }.new }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before { login_as(user) }

  context "without the view_budgets permission" do
    let(:permissions) { %i[view_work_packages] }

    it "hides the budget" do
      expect(exporter.allowed_to_view_attribute?(work_package, :budget)).to be(false)
    end
  end

  context "with the view_budgets permission" do
    let(:permissions) { %i[view_work_packages view_budgets] }

    it "shows the budget" do
      expect(exporter.allowed_to_view_attribute?(work_package, :budget)).to be(true)
    end
  end
end
