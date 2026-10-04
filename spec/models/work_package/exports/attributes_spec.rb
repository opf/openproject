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

RSpec.describe WorkPackage::Exports::Attributes do
  shared_let(:project) { create(:project) }
  shared_let(:work_package) { create(:work_package, project:) }

  let(:exporter) { Class.new { include WorkPackage::Exports::Attributes }.new }
  let(:permissions) { %i[view_work_packages] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before { login_as(user) }

  describe "#allowed_to_view_attribute?" do
    it "allows attributes without a registered check" do
      expect(exporter.allowed_to_view_attribute?(work_package, :subject)).to be(true)
    end

    it "allows every attribute of objects other than work packages" do
      expect(exporter.allowed_to_view_attribute?(project, :project_phase)).to be(true)
    end

    describe "project_phase" do
      before { create(:project_phase, project:) }

      it "is hidden without the view_project_phases permission" do
        expect(exporter.allowed_to_view_attribute?(work_package, :project_phase)).to be(false)
      end

      context "with the view_project_phases permission" do
        let(:permissions) { %i[view_work_packages view_project_phases] }

        it "is visible" do
          expect(exporter.allowed_to_view_attribute?(work_package, :project_phase)).to be(true)
        end
      end
    end
  end

  describe ".add_attribute_visibility_check" do
    before do
      allow(described_class).to receive(:attribute_visibility_checks).and_return({})
    end

    it "gates each given attribute by the check" do
      described_class.add_attribute_visibility_check(:foo, :bar) { |wp| wp.subject == "visible" }

      expect(described_class.attribute_visibility_checks.keys).to contain_exactly(:foo, :bar)
      expect(described_class.attribute_visibility_checks[:foo].call(work_package)).to be(false)
    end
  end
end
