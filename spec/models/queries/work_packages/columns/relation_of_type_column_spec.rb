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
require_relative 'shared_query_column_specs'

describe Queries::WorkPackages::Columns::RelationOfTypeColumn, type: :model do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:type) { FactoryGirl.build_stubbed(:type) }
  let(:instance) { described_class.new(type) }
  let(:enterprise_token_allows) { true }

  it_behaves_like 'query column'

  describe 'instances' do
    before do
      stub_const('Relation::TYPES',
                 relation1: { name: :label_relates_to, sym_name: :label_relates_to, order: 1, sym: :relation1 },
                 relation2: { name: :label_duplicates, sym_name: :label_duplicated_by, order: 2, sym: :relation2 })

      allow(EnterpriseToken)
        .to receive(:allows_to?)
        .with(:work_package_query_relation_columns)
        .and_return(enterprise_token_allows)
    end

    context 'with a valid enterprise token' do
      it 'contains the type columns' do
        expect(described_class.instances.length)
          .to eq 2

        expect(described_class.instances[0].sym)
          .to eq :relation1

        expect(described_class.instances[1].sym)
          .to eq :relation2
      end
    end

    context 'without a valid enterprise token' do
      let(:enterprise_token_allows) { false }

      it 'is empty' do
        expect(described_class.instances)
          .to be_empty
      end
    end
  end
end
