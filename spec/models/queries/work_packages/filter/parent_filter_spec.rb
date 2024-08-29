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

RSpec.describe Queries::WorkPackages::Filter::ParentFilter do
  let(:project) { build_stubbed(:project) }
  let(:query) do
    build_stubbed(:query, project:)
  end

  it_behaves_like "basic query filter" do
    let(:class_key) { :parent }
    let(:type) { :list }

    before do
      instance.context = query
    end

    describe "#available?" do
      context "within a project" do
        it "is true if any work package exists and is visible" do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :exists?)
            .with(no_args)
            .with(project)
            .with(no_args)
            .and_return true

          expect(instance).to be_available
        end

        it "is false if no work package exists/ is visible" do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :exists?)
            .with(no_args)
            .with(project)
            .with(no_args)
            .and_return false

          expect(instance).not_to be_available
        end
      end

      context "outside of a project" do
        let(:project) { nil }

        it "is true if any work package exists and is visible" do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :exists?)
            .with(no_args)
            .and_return true

          expect(instance).to be_available
        end

        it "is false if no work package exists/ is visible" do
          allow(WorkPackage)
            .to receive_message_chain(:visible, :exists?)
            .with(no_args)
            .and_return false

          expect(instance).not_to be_available
        end
      end
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance).to be_ar_object_filter
      end
    end

    describe "#allowed_values" do
      it "raises an error" do
        expect { instance.allowed_values }.to raise_error NotImplementedError
      end
    end

    describe "#value_object" do
      let(:visible_wp) { build_stubbed(:work_package) }

      it "returns the work package for the values" do
        allow(WorkPackage)
          .to receive_message_chain(:visible, :for_projects, :find)
          .with(no_args)
          .with(project)
          .with(instance.values)
          .and_return([visible_wp])

        expect(instance.value_objects)
          .to contain_exactly(visible_wp)
      end

      context "with the 'templated' value" do
        before do
          instance.values = ["templated"]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :find)
            .with(no_args)
            .with(project)
            .with([])
            .and_return([])
        end

        it "returns a TemplatedValue object" do
          expect(instance.value_objects.length).to be 1
          expect(instance.value_objects[0].id).to eql "{id}"
        end
      end
    end

    describe "#allowed_objects" do
      it "raises an error" do
        expect { instance.allowed_objects }.to raise_error NotImplementedError
      end
    end

    describe "#valid_values!" do
      let(:visible_wp) { build_stubbed(:work_package) }
      let(:invisible_wp) { build_stubbed(:work_package) }

      context "within a project" do
        it "removes all non existing/non visible ids" do
          instance.values = [visible_wp.id.to_s, invisible_wp.id.to_s, "999999"]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :where, :pluck)
            .with(no_args)
            .with(project)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          instance.valid_values!

          expect(instance.values)
            .to contain_exactly(visible_wp.id.to_s)
        end
      end

      context "outside of a project" do
        let(:project) { nil }

        it "removes all non existing/non visible ids" do
          instance.values = [visible_wp.id.to_s, invisible_wp.id.to_s, "999999"]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :where, :pluck)
            .with(no_args)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          instance.valid_values!

          expect(instance.values)
            .to contain_exactly(visible_wp.id.to_s)
        end
      end
    end

    describe "#validate" do
      let(:visible_wp) { build_stubbed(:work_package) }
      let(:invisible_wp) { build_stubbed(:work_package) }

      context "with old templated value" do
        it "is still valid" do
          instance.values = %w[templated]
          expect(instance).to be_valid
        end
      end

      context "with new templated value" do
        it "is still valid" do
          instance.values = %w[{id}]
          expect(instance).to be_valid
        end
      end

      context "within a project" do
        it "is valid if only visible wps are values" do
          instance.values = [visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :where, :pluck)
            .with(no_args)
            .with(project)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).to be_valid
        end

        it "is invalid if invisible wps are values" do
          instance.values = [invisible_wp.id.to_s, visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :for_projects, :where, :pluck)
            .with(no_args)
            .with(project)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).not_to be_valid
        end
      end

      context "outside of a project" do
        let(:project) { nil }

        it "is valid if only visible wps are values" do
          instance.values = [visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :where, :pluck)
            .with(no_args)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).to be_valid
        end

        it "is invalid if invisible wps are values" do
          instance.values = [invisible_wp.id.to_s, visible_wp.id.to_s]

          allow(WorkPackage)
            .to receive_message_chain(:visible, :where, :pluck)
            .with(no_args)
            .with(id: instance.values)
            .with(:id)
            .and_return([visible_wp.id])

          expect(instance).not_to be_valid
        end
      end
    end

    describe "#where and #includes" do
      let(:parent) { create(:work_package) }
      let(:visible_wp) { create(:work_package, parent:) }

      before do
        visible_wp
        instance.values = [parent.id.to_s]
        instance.operator = "="
      end

      it "filters" do
        scope = WorkPackage
                .references(instance.includes)
                .includes(instance.includes)
                .where(instance.where)

        expect(scope)
          .to contain_exactly(visible_wp)
      end
    end
  end
end
