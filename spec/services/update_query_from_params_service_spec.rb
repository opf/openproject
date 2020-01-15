#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe UpdateQueryFromParamsService,
         type: :model do

  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:query) { FactoryBot.build_stubbed(:query) }

  let(:instance) { described_class.new(query, user) }

  let(:params) { {} }

  describe '#call' do
    subject { instance.call(params) }

    context 'group_by' do
      context 'for an existing value' do
        let(:params) { { group_by: 'status' } }

        it 'sets the value' do
          subject

          expect(query.group_by)
            .to eql('status')
        end
      end

      context 'for an explicitly nil value' do
        let(:params) { { group_by: nil } }

        it 'sets the value' do
          subject

          expect(query.group_by)
            .to eql(nil)
        end
      end
    end

    context 'filters' do
      let(:params) do
        { filters: [{ field: 'status_id', operator: '=', values: ['1', '2'] }] }
      end

      context 'for a valid filter' do
        it 'sets the filter' do
          subject

          expect(query.filters.length)
            .to eql(1)
          expect(query.filters[0].name)
            .to eql(:status_id)
          expect(query.filters[0].operator)
            .to eql('=')
          expect(query.filters[0].values)
            .to eql(['1', '2'])
        end
      end
    end

    context 'sort_by' do
      let(:params) do
        { sort_by: [['status_id', 'desc']] }
      end

      it 'sets the order' do
        subject

        expect(query.sort_criteria)
          .to eql([['status_id', 'desc']])
      end
    end

    context 'columns' do
      let(:params) do
        { columns: ['assigned_to', 'author', 'category', 'subject'] }
      end

      it 'sets the columns' do
        subject

        expect(query.column_names)
          .to match_array(params[:columns].map(&:to_sym))
      end
    end

    context 'display representation' do
      let(:params) do
        { display_representation: 'list' }
      end

      it 'sets the display_representation' do
        subject

        expect(query.display_representation)
          .to eq('list')
      end
    end

    context 'highlighting mode', with_ee: %i[conditional_highlighting] do
      let(:params) do
        { highlighting_mode: 'status' }
      end

      it 'sets the highlighting_mode' do
        subject

        expect(query.highlighting_mode)
          .to eq(:status)
      end
    end

    context 'default highlighting mode', with_ee: %i[conditional_highlighting] do
      let(:params) do
        { }
      end

      it 'sets the highlighting_mode' do
        subject

        expect(query.highlighting_mode)
          .to eq(:inline)
      end
    end

    context 'highlighting mode without EE' do
      let(:params) do
        { highlighting_mode: 'status' }
      end

      it 'sets the highlighting_mode' do
        subject

        expect(query.highlighting_mode)
          .to eq(:none)
      end
    end
  end
end
