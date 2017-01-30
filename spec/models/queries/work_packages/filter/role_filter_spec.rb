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

describe Queries::WorkPackages::Filter::RoleFilter, type: :model do
  let(:role) { FactoryGirl.build_stubbed(:role) }

  it_behaves_like 'basic query filter' do
    let(:order) { 7 }
    let(:type) { :list_optional }
    let(:class_key) { :assigned_to_role }
    let(:name) { I18n.t('query_fields.assigned_to_role') }

    describe '#available?' do
      it 'is true if any givable role exists' do
        allow(Role)
          .to receive_message_chain(:givable, :exists?)
          .and_return true

        expect(instance).to be_available
      end

      it 'is false if no givable role exists' do
        allow(Group)
          .to receive_message_chain(:givable, :exists?)
          .and_return false

        expect(instance).to_not be_available
      end
    end

    describe '#allowed_values' do
      before do
        allow(Role)
          .to receive(:givable)
          .and_return [role]
      end

      it 'is an array of role values' do
        expect(instance.allowed_values)
          .to match_array [[role.name, role.id.to_s]]
      end
    end

    describe '#ar_object_filter?' do
      it 'is true' do
        expect(instance)
          .to be_ar_object_filter
      end
    end

    describe '#value_objects' do
      let(:role2) { FactoryGirl.build_stubbed(:role) }

      before do
        allow(Role)
          .to receive(:givable)
          .and_return([role, role2])

        instance.values = [role.id.to_s, role2.id.to_s]
      end

      it 'returns an array of projects' do
        expect(instance.value_objects)
          .to match_array([role, role2])
      end
    end
  end
end
