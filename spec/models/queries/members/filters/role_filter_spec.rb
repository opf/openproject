#-- encoding: UTF-8

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

describe Queries::Members::Filters::RoleFilter, type: :model do
  let(:role1) { FactoryGirl.build_stubbed(:role) }
  let(:role2) { FactoryGirl.build_stubbed(:role) }

  before do
    allow(Role)
      .to receive(:pluck)
      .with(:name, :id)
      .and_return([[role1.name, role1.id], [role2.name, role2.id]])
  end

  it_behaves_like 'basic query filter' do
    let(:class_key) { :role_id }
    let(:type) { :list_optional }
    let(:name) { Member.human_attribute_name(:role) }

    describe '#allowed_values' do
      it 'is a list of the possible values' do
        expected = [[role1.name, role1.id], [role2.name, role2.id]]

        expect(instance.allowed_values).to match_array(expected)
      end
    end
  end

  it_behaves_like 'list_optional query filter' do
    let(:attribute) { :role_id }
    let(:model) { Member }
    let(:joins) { :member_roles }
    let(:valid_values) { [role1.id.to_s] }
  end
end
