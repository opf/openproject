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

require "spec_helper"

RSpec.describe UpdateProjectsTypesService do
  let(:project) { instance_double(Project, types_used_by_work_packages: []) }
  let(:standard_type) { build_stubbed(:type_standard) }

  subject(:instance) { described_class.new(project) }

  before do
    allow(Type).to receive(:standard_type).and_return standard_type
  end

  describe ".call" do
    subject { instance.call(ids) }

    before do
      allow(project).to receive(:type_ids=)
    end

    shared_examples "activating custom fields" do
      let(:project) { create(:project, no_types: true) }
      let!(:custom_field) { create(:text_wp_custom_field, types:) }

      it "updates the active custom fields" do
        expect { subject }
          .to change { project.reload.work_package_custom_field_ids }
          .from([])
          .to([custom_field.id])
      end

      it "does not activates the same custom field twice" do
        expect { subject }.to change { project.reload.work_package_custom_field_ids }
        expect { subject }.not_to change { project.reload.work_package_custom_field_ids }
      end

      context "for a project with already existing types" do
        let(:project) { create(:project, types:, work_package_custom_fields: [create(:text_wp_custom_field)]) }

        it "does not change custom fields" do
          expect { subject }.not_to change { project.reload.work_package_custom_field_ids }
        end
      end
    end

    context "with ids provided" do
      let(:ids) { [1, 2, 3] }

      it "returns true and updates the ids" do
        expect(subject).to be_truthy
        expect(project).to have_received(:type_ids=).with(ids)
      end

      include_examples "activating custom fields" do
        let(:types) { create_list(:type, 2) }
        let(:ids) { types.collect(&:id) }
      end
    end

    context "with no id passed" do
      let(:ids) { [] }

      it "adds the id of the default type and returns true" do
        expect(subject).to be_truthy
        expect(project).to have_received(:type_ids=).with([standard_type.id])
      end

      include_examples "activating custom fields" do
        let(:standard_type) { create(:type_standard) }
        let(:types) { [standard_type] }
      end
    end

    context "with nil passed" do
      let(:ids) { nil }

      it "adds the id of the default type and returns true" do
        expect(subject).to be_truthy
        expect(project).to have_received(:type_ids=).with([standard_type.id])
      end

      include_examples "activating custom fields" do
        let(:standard_type) { create(:type_standard) }
        let(:types) { [standard_type] }
      end
    end

    context "when the id of a type in use is not provided" do
      let(:type) { build_stubbed(:type) }
      let(:ids) { [1] }

      before do
        allow(project).to receive(:types_used_by_work_packages).and_return([type])
        allow(project).to receive(:work_package_custom_field_ids=).and_return([type])
      end

      it "returns false and sets an error message" do
        errors = instance_double(ActiveModel::Errors)
        allow(errors).to receive(:add)
        allow(project).to receive(:errors).and_return(errors)

        expect(subject).to be_falsey
        expect(errors).to have_received(:add).with(:types, :in_use_by_work_packages, types: type.name)
        expect(project).not_to have_received(:type_ids=)
        expect(project).not_to have_received(:work_package_custom_field_ids=)
      end
    end
  end
end
