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

describe Queries::WorkPackages::Filter::TypeFilter, type: :model do
  it_behaves_like 'basic query filter' do
    let(:order) { 3 }
    let(:type) { :list }
    let(:class_key) { :type_id }

    describe '#available?' do
      context 'within a project' do
        before do
          allow(project)
            .to receive_message_chain(:rolled_up_types, :exists?)
            .and_return true
        end

        it 'is true' do
          expect(instance).to be_available
        end

        it 'is false without a type' do
          allow(project)
            .to receive_message_chain(:rolled_up_types, :exists?)
            .and_return false

          expect(instance).to_not be_available
        end
      end

      context 'without a project' do
        let(:project) { nil }

        before do
          allow(Type)
            .to receive_message_chain(:order, :exists?)
            .and_return true
        end

        it 'is true' do
          expect(instance).to be_available
        end

        it 'is false without a type' do
          allow(Type)
            .to receive_message_chain(:order, :exists?)
            .and_return false

          expect(instance).to_not be_available
        end
      end
    end

    describe '#allowed_values' do
      let(:type) { FactoryGirl.build_stubbed(:type) }
      context 'within a project' do
        before do
          allow(project)
            .to receive(:rolled_up_types)
            .and_return [type]
        end

        it 'returns an array of type options' do
          expect(instance.allowed_values)
            .to match_array [[type.name, type.id.to_s]]
        end
      end

      context 'without a project' do
        let(:project) { nil }

        before do
          allow(Type)
            .to receive_message_chain(:order)
            .and_return [type]
        end

        it 'returns an array of type options' do
          expect(instance.allowed_values)
            .to match_array [[type.name, type.id.to_s]]
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
      let(:type1) { FactoryGirl.build_stubbed(:type) }
      let(:type2) { FactoryGirl.build_stubbed(:type) }

      before do
        allow(project)
          .to receive(:rolled_up_types)
          .and_return([type1, type2])

        instance.values = [type1.id.to_s, type2.id.to_s]
      end

      it 'returns an array of types' do
        expect(instance.value_objects)
          .to match_array([type1, type2])
      end
    end
  end
end
