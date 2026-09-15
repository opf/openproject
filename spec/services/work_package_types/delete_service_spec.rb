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

RSpec.describe WorkPackageTypes::DeleteService do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type, name: "Bug") }

  subject(:service) { described_class.new(user: admin, model: type) }

  context "when no project uses the type" do
    it "deletes it along with its base variant" do
      variant = type.default_variant

      expect(service.call).to be_success
      expect { type.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { variant.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  context "when projects use the type" do
    let!(:project) { create(:project, types: [type]) }
    let!(:other_project) { create(:project, types: [type]) }

    it "deletes it and takes it away from those projects" do
      expect(service.call).to be_success
      expect { type.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(project.reload.enabled_types).to be_empty
      expect(other_project.reload.enabled_types).to be_empty
    end
  end

  context "when the type still carries work packages" do
    let!(:project) { create(:project, types: [type]) }
    let!(:work_package) { create(:work_package, project:, type:) }

    it "refuses and says why, leaving the projects on the type" do
      result = service.call

      expect(result).to be_failure
      expect(result.errors.full_messages)
        .to eq([I18n.t("activerecord.errors.models.type.attributes.base.in_use_by_work_packages")])
      expect(type.reload).to be_present
      expect(project.reload.enabled_types).to contain_exactly(type)
    end
  end

  context "when another type's variant borrows configuration from this one" do
    let!(:project) { create(:project, types: [type]) }

    before do
      borrower = create(:type_variant, type: create(:type, name: "Feature"), variant_name: "Borrower")
      borrower.update_columns(workflows_source_id: type.default_variant.id)
    end

    it "keeps the type and leaves the projects using it" do
      expect(service.call).to be_failure
      expect(type.reload).to be_present
      expect(project.reload.enabled_types).to contain_exactly(type)
    end
  end

  context "when the user is not an administrator" do
    subject(:service) { described_class.new(user: create(:user), model: type) }

    it "refuses" do
      expect(service.call).to be_failure
      expect(type.reload).to be_present
    end
  end
end
