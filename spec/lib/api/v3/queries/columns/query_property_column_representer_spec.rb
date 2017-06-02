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

describe ::API::V3::Queries::Columns::QueryPropertyColumnRepresenter do
  include ::API::V3::Utilities::PathHelper

  let(:column) { Query.available_columns.detect { |column| column.name == :status } }
  let(:representer) { described_class.new(column) }

  subject { representer.to_json }

  describe 'generation' do
    describe '_links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.query_column 'status' }
        let(:title) { 'Status' }
      end
    end

    it 'has _type QueryColumn' do
      is_expected
        .to be_json_eql('QueryColumn'.to_json)
        .at_path('_type')
    end

    it 'has id attribute' do
      is_expected
        .to be_json_eql('status'.to_json)
        .at_path('id')
    end

    it 'has name attribute' do
      is_expected
        .to be_json_eql('Status'.to_json)
        .at_path('name')
    end

    context 'for a translated column' do
      let(:column) { Query.available_columns.detect { |column| column.name == :assigned_to } }

      describe '_links' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'self' }
          let(:href) { api_v3_paths.query_column 'assignee' }
          let(:title) { 'Assignee' }
        end
      end

      it 'has id attribute' do
        is_expected
          .to be_json_eql('assignee'.to_json)
          .at_path('id')
      end

      it 'has name attribute' do
        is_expected
          .to be_json_eql('Assignee'.to_json)
          .at_path('name')
      end
    end
  end
end
