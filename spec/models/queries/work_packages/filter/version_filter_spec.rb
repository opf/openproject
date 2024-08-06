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

RSpec.describe Queries::WorkPackages::Filter::VersionFilter do
  let(:version) { build_stubbed(:version) }

  it_behaves_like "basic query filter" do
    let(:type) { :list_optional }
    let(:class_key) { :version_id }
    let(:values) { [version.id.to_s] }
    let(:name) { WorkPackage.human_attribute_name("version") }

    before do
      if project
        allow(project)
          .to receive_message_chain(:shared_versions, :pluck)
          .and_return [version.id]
      else
        allow(Version)
          .to receive_message_chain(:visible, :systemwide, :pluck)
          .and_return [version.id]
      end
    end

    describe "#valid?" do
      context "within a project" do
        it "is true if the value exists as a version" do
          expect(instance).to be_valid
        end

        it "is false if the value does not exist as a version" do
          allow(project)
            .to receive_message_chain(:shared_versions, :pluck)
            .and_return []

          expect(instance).not_to be_valid
        end
      end

      context "outside of a project" do
        let(:project) { nil }

        it "is true if the value exists as a version" do
          expect(instance).to be_valid
        end

        it "is false if the value does not exist as a version" do
          allow(Version)
            .to receive_message_chain(:visible, :systemwide, :pluck)
            .and_return []

          expect(instance).not_to be_valid
        end
      end
    end

    describe "#allowed_values" do
      context "within a project" do
        before do
          expect(instance.allowed_values)
            .to contain_exactly([version.id.to_s, version.id.to_s])
        end
      end

      context "outside of a project" do
        let(:project) { nil }

        before do
          expect(instance.allowed_values)
            .to contain_exactly([version.id.to_s, version.id.to_s])
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
      let(:version1) { build_stubbed(:version) }
      let(:version2) { build_stubbed(:version) }

      before do
        allow(project)
          .to receive(:shared_versions)
          .and_return([version1, version2])

        instance.values = [version1.id.to_s]
      end

      it "returns an array of versions" do
        expect(instance.value_objects)
          .to contain_exactly(version1)
      end
    end
  end
end
