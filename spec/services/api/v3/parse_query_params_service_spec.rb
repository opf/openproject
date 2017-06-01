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

describe ::API::V3::ParseQueryParamsService,
         type: :model do

  let(:instance) { described_class.new }
  let(:params) { {} }

  describe '#call' do
    subject { instance.call(params) }

    shared_examples_for 'transforms' do
      it 'is success' do
        expect(subject)
          .to be_success
      end

      it 'is transformed' do
        expect(subject.result)
          .to eql(expected)
      end
    end

    context 'with group by' do
      context 'as groupBy' do
        it_behaves_like 'transforms' do
          let(:params) { { groupBy: 'status' } }
          let(:expected) { { group_by: 'status' } }
        end
      end

      context 'as group_by' do
        it_behaves_like 'transforms' do
          let(:params) { { group_by: 'status' } }
          let(:expected) { { group_by: 'status' } }
        end
      end

      context 'as "g"' do
        it_behaves_like 'transforms' do
          let(:params) { { g: 'status' } }
          let(:expected) { { group_by: 'status' } }
        end
      end

      context 'with an attribute called differently in v3' do
        it_behaves_like 'transforms' do
          let(:params) { { groupBy: 'assignee' } }
          let(:expected) { { group_by: 'assigned_to' } }
        end
      end
    end

    context 'with columns' do
      context 'as columns' do
        it_behaves_like 'transforms' do
          let(:params) { { columns: ['status', 'assignee'] } }
          let(:expected) { { columns: ['status', 'assigned_to'] } }
        end
      end

      context 'as "c"' do
        it_behaves_like 'transforms' do
          let(:params) { { c: ['status', 'assignee'] } }
          let(:expected) { { columns: ['status', 'assigned_to'] } }
        end
      end

      context 'as column_names' do
        it_behaves_like 'transforms' do
          let(:params) { { column_names: ['status', 'assignee'] } }
          let(:expected) { { columns: ['status', 'assigned_to'] } }
        end
      end
    end

    context 'with sort' do
      context 'as sortBy in comma separated value' do
        it_behaves_like 'transforms' do
          let(:params) { { sortBy: JSON::dump([['status', 'desc']]) } }
          let(:expected) { { sort_by: [['status', 'desc']] } }
        end
      end

      context 'as sortBy in colon concatenated value' do
        it_behaves_like 'transforms' do
          let(:params) { { sortBy: JSON::dump(['status:desc']) } }
          let(:expected) { { sort_by: [['status', 'desc']] } }
        end
      end

      context 'with an invalid JSON' do
        let(:params) { { sortBy: 'faulty' + JSON::dump(['status:desc']) } }

        it 'is not success' do
          expect(subject)
            .to_not be_success
        end

        it 'returns the error' do
          message = 'unexpected token at \'faulty["status:desc"]\''

          expect(subject.errors.messages[:base].length)
            .to eql(1)
          expect(subject.errors.messages[:base][0])
            .to end_with(message)
        end
      end
    end

    context 'with filters' do
      context 'as filters in dumped json' do
        context 'with a filter named internally' do
          it_behaves_like 'transforms' do
            let(:params) do
              { filters: JSON::dump([{ 'status_id' => { 'operator' => '=',
                                                        'values' => ['1', '2'] } }]) }
            end
            let(:expected) do
              { filters: [{ field: 'status_id', operator: '=', values: ['1', '2'] }] }
            end
          end
        end

        context 'with a filter named according to v3' do
          it_behaves_like 'transforms' do
            let(:params) do
              { filters: JSON::dump([{ 'status' => { 'operator' => '=',
                                                     'values' => ['1', '2'] } }]) }
            end
            let(:expected) do
              { filters: [{ field: 'status_id', operator: '=', values: ['1', '2'] }] }
            end
          end

          it_behaves_like 'transforms' do
            let(:params) do
              { filters: JSON::dump([{ 'subprojectId' => { 'operator' => '=',
                                                           'values' => ['1', '2'] } }]) }
            end
            let(:expected) do
              { filters: [{ field: 'subproject_id', operator: '=', values: ['1', '2'] }] }
            end
          end

          it_behaves_like 'transforms' do
            let(:params) do
              { filters: JSON::dump([{ 'watcher' => { 'operator' => '=',
                                                      'values' => ['1', '2'] } }]) }
            end
            let(:expected) do
              { filters: [{ field: 'watcher_id', operator: '=', values: ['1', '2'] }] }
            end
          end

          it_behaves_like 'transforms' do
            let(:params) do
              { filters: JSON::dump([{ 'custom_field_1' => { 'operator' => '=',
                                                             'values' => ['1', '2'] } }]) }
            end
            let(:expected) do
              { filters: [{ field: 'cf_1', operator: '=', values: ['1', '2'] }] }
            end
          end
        end

        context 'with an invalid JSON' do
          let(:params) do
            { filters: 'faulty' + JSON::dump([{ 'status' => { 'operator' => '=',
                                                              'values' => ['1', '2'] } }]) }
          end

          it 'is not success' do
            expect(subject)
              .to_not be_success
          end

          it 'returns the error' do
            message = 'unexpected token at ' +
                      "'faulty[{\"status\":{\"operator\":\"=\",\"values\":[\"1\",\"2\"]}}]'"

            expect(subject.errors.messages[:base].length)
              .to eql(1)
            expect(subject.errors.messages[:base][0])
              .to end_with(message)
          end
        end

        context 'with an empty array (in JSON)' do
          it_behaves_like 'transforms' do
            let(:params) do
              { filters: JSON::dump([]) }
            end
            let(:expected) do
              { filters: [] }
            end
          end
        end
      end
    end

    context 'with showSums' do
      it_behaves_like 'transforms' do
        let(:params) { { showSums: 'true' } }
        let(:expected) { { display_sums: true } }
      end

      it_behaves_like 'transforms' do
        let(:params) { { showSums: 'false' } }
        let(:expected) { { display_sums: false } }
      end
    end
  end
end
