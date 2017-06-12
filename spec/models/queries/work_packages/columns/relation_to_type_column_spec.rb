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

describe Queries::WorkPackages::Columns::RelationToTypeColumn, type: :model do
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:type) { FactoryGirl.build_stubbed(:type) }
  let(:instance) { described_class.new(type) }

  it_behaves_like 'query column'

  describe 'instances' do
    context 'within project' do
      before do
        allow(project)
          .to receive(:types)
          .and_return([type])
      end

      it 'contains the type columns' do
        expect(described_class.instances(project).length)
          .to eq 1

        expect(described_class.instances(project)[0].type)
          .to eq type
      end
    end

    context 'global' do
      before do
        allow(Type)
          .to receive(:all)
          .and_return([type])
      end

      it 'contains the type columns' do
        expect(described_class.instances.length)
          .to eq 1

        expect(described_class.instances[0].type)
          .to eq type
      end
    end
  end
end
