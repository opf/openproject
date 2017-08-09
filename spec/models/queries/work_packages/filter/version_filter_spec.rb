#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Queries::WorkPackages::Filter::VersionFilter, type: :model do
  let(:version) { FactoryGirl.build_stubbed(:version) }

  it_behaves_like 'basic query filter' do
    let(:order) { 7 }
    let(:type) { :list_optional }
    let(:class_key) { :fixed_version_id }
    let(:values) { [version.id.to_s] }
    let(:name) { WorkPackage.human_attribute_name('fixed_version') }

    before do
      if project
        allow(project)
          .to receive_message_chain(:shared_versions)
          .and_return [version]
      else
        allow(Version)
          .to receive_message_chain(:visible, :systemwide)
          .and_return [version]
      end
    end

    describe '#valid?' do
      context 'within a project' do
        it 'is true if the value exists as a version' do
          expect(instance).to be_valid
        end

        it 'is false if the value does not exist as a version' do
          allow(project)
            .to receive_message_chain(:shared_versions)
            .and_return []

          expect(instance).to_not be_valid
        end
      end

      context 'outside of a project' do
        let(:project) { nil }

        it 'is true if the value exists as a version' do
          expect(instance).to be_valid
        end

        it 'is false if the value does not exist as a version' do
          allow(Version)
            .to receive_message_chain(:visible, :systemwide)
            .and_return []

          expect(instance).to_not be_valid
        end
      end
    end

    describe '#allowed_values' do
      context 'within a project' do
        before do
          expect(instance.allowed_values)
            .to match_array [[version.name, version.id.to_s]]
        end
      end

      context 'outside of a project' do
        let(:project) { nil }

        before do
          expect(instance.allowed_values)
            .to match_array [[version.name, version.id.to_s]]
        end
      end
    end

    describe '#ar_object_filter?' do
      it 'is true' do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe '#value_objects' do
      let(:version1) { FactoryGirl.build_stubbed(:version) }
      let(:version2) { FactoryGirl.build_stubbed(:version) }

      before do
        allow(project)
          .to receive(:shared_versions)
          .and_return([version1, version2])

        instance.values = [version1.id.to_s]
      end

      it 'returns an array of versions' do
        expect(instance.value_objects)
          .to match_array([version1])
      end
    end
  end
end
