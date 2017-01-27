#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.

require 'spec_helper'

describe ParseSchemaFilterParamsService do
  let(:current_user) { FactoryGirl.build_stubbed(:user) }
  let(:instance) { described_class.new(user: current_user) }
  let(:project) { FactoryGirl.build_stubbed(:project) }
  let(:type) { FactoryGirl.build_stubbed(:type) }

  describe '#call' do
    let(:filter) do
      [{ 'id' => { 'values' => ["#{project.id}-#{type.id}"], 'operator' => '=' } }]
    end
    let(:result) { instance.call(filter) }

    let(:found_projects) { [project] }
    let(:found_types) { [type] }

    before do
      visible_projects = double('visible_projects')

      allow(Project)
        .to receive(:visible)
        .with(current_user)
        .and_return(visible_projects)

      allow(visible_projects)
        .to receive(:where)
        .with(id: [project.id.to_s])
        .and_return(found_projects)

      allow(Type)
        .to receive(:where)
        .with(id: [type.id.to_s])
        .and_return(found_types)
    end

    context 'valid' do
      it 'is a success' do
        expect(result).to be_success
      end

      it 'returns the [project, type] pair' do
        expect(result.result).to match_array [[project, type]]
      end
    end

    context 'for a non existing project' do
      let(:found_projects) { [] }

      it 'is a success' do
        expect(result).to be_success
      end

      it 'returns an empty array' do
        expect(result.result).to match_array []
      end
    end

    context 'for a non existing type' do
      let(:found_types) { [] }

      it 'is a success' do
        expect(result).to be_success
      end

      it 'returns an empty array' do
        expect(result.result).to match_array []
      end
    end

    context 'without the "=" operator' do
      let(:filter) do
        [{ 'id' => { 'values' => ["#{project.id}-#{type.id}"], 'operator' => '!' } }]
      end

      it 'is a failure' do
        expect(result).not_to be_success
      end

      it 'returns an empty array' do
        expect(result.result).to be_nil
      end

      it 'returns an error message' do
        expect(result.errors.messages[:base]).to match_array ['The operator is not supported.']
      end
    end

    context 'with an invalid value' do
      let(:filter) do
        [{ 'id' => { 'values' => ["bogus-1"], 'operator' => "=" } }]
      end

      it 'is a failure' do
        expect(result).not_to be_success
      end

      it 'returns an empty array' do
        expect(result.result).to be_nil
      end

      it 'returns an error message' do
        expect(result.errors.messages[:base]).to match_array ['A value is invalid.']
      end
    end

    context 'without an id filter' do
      let(:filter) do
        [{}]
      end

      it 'is a failure' do
        expect(result).not_to be_success
      end

      it 'returns an empty array' do
        expect(result.result).to be_nil
      end

      it 'returns an error message' do
        expect(result.errors.messages[:base]).to match_array ['An \'id\' filter is required.']
      end
    end
  end
end
