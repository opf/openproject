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

RSpec.describe Queries::WorkPackages::Filter::TypeFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :type_id }

    describe "#available?" do
      context "within a project" do
        before do
          allow(project)
            .to receive_message_chain(:rolled_up_types, :exists?)
            .and_return true
        end

        it "is true" do
          expect(instance).to be_available
        end

        it "is false without a type" do
          allow(project)
            .to receive_message_chain(:rolled_up_types, :exists?)
            .and_return false

          expect(instance).not_to be_available
        end
      end

      context "without a project" do
        let(:project) { nil }
        let!(:root) { create(:type) }

        it "is true" do
          allow(Type).to receive(:roots).and_return(Type.where(id: root.id))

          expect(instance).to be_available
        end

        it "is false without a type" do
          allow(Type).to receive(:roots).and_return(Type.none)

          expect(instance).not_to be_available
        end
      end
    end

    describe "#allowed_values" do
      let(:type) { build_stubbed(:type) }

      context "within a project" do
        before do
          allow(project)
            .to receive(:rolled_up_types)
            .and_return [type]
        end

        it "returns an array of type options" do
          expect(instance.allowed_values)
            .to contain_exactly([type.name, type.id.to_s])
        end
      end

      context "without a project" do
        let(:project) { nil }
        let!(:root) { create(:type) }

        before do
          allow(Type).to receive(:roots).and_return(Type.where(id: root.id))
        end

        it "returns an array of type options" do
          expect(instance.allowed_values)
            .to contain_exactly([root.displayed_name, root.id.to_s])
        end
      end
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe "#value_objects" do
      let(:type1) { build_stubbed(:type) }
      let(:type2) { build_stubbed(:type) }

      before do
        allow(project)
          .to receive(:rolled_up_types)
          .and_return([type1, type2])

        instance.values = [type1.id.to_s, type2.id.to_s]
      end

      it "returns an array of types" do
        expect(instance.value_objects)
          .to contain_exactly(type1, type2)
      end
    end

    describe "#where" do
      let(:project) { nil }
      let!(:root) { create(:type) }
      let!(:sub_type) { create(:type, parent: root) }

      before do
        instance.operator = "="
        instance.values = [root.id.to_s]
      end

      it "expands a root type to include its sub-types" do
        expect(instance.where)
          .to include(root.id.to_s, sub_type.id.to_s)
      end

      it "leaves a childless type unchanged" do
        instance.values = [sub_type.id.to_s]

        expect(instance.where)
          .not_to include(root.id.to_s)
      end

      it "returns work packages of the root type and its sub-types, but not unrelated types" do
        root_work_package = create(:work_package, type: root)
        sub_work_package = create(:work_package, type: sub_type)
        create(:work_package, type: create(:type))

        expect(WorkPackage.where(instance.where))
          .to contain_exactly(root_work_package, sub_work_package)
      end
    end
  end
end
