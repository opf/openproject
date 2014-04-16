#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
#++

require File.expand_path('../../../../spec_helper', __FILE__)

describe Api::V3::WorkPackagesController do
  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    allow(User).to receive(:current).and_return(current_user)
  end

  describe '#index' do
    context 'with no work packages available' do
      it 'assigns an empty work packages array' do
        get 'index', format: 'xml'
        expect(assigns(:work_packages)).to eq([])
      end

      it 'renders the index template' do
        get 'index', format: 'xml'
        expect(response).to render_template('api/v3/work_packages/index', formats: %w(api))
      end
    end
  end

  describe '#column_data' do
    context 'with incorrect parameters' do
      specify {
        expect { get :column_data, format: 'xml' }.to raise_error(/API Error/)
      }

      specify {
        expect { get :column_data, format: 'xml', ids: [1, 2] }.to raise_error(/API Error/)
      }

      specify {
        expect { get :column_data, format: 'xml', column_names: %w(subject status) }.to raise_error(/API Error/)
      }
    end

    context 'with column ids and column names' do
      before do
        # N.B.: for the purpose of example only. It makes little sense to sum a ratio.
        allow(Setting).to receive(:work_package_list_summable_columns).and_return(
          %w(estimated_hours done_ratio)
        )
        WorkPackage.stub_chain(:visible, :find) {
          FactoryGirl.create_list(:work_package, 2, estimated_hours: 5, done_ratio: 33)
        }
      end

      it 'handles incorrect column names' do
        expect { get :column_data, format: 'xml', ids: [1, 2], column_names: %w(non_existent status) }.to raise_error(/API Error/)
      end

      it 'assigns column data' do
        get :column_data, format: 'xml', ids: [1, 2], column_names: %w(subject status estimated_hours)

        expect(assigns(:columns_data).size).to eq(3)
        expect(assigns(:columns_data).first.size).to eq(2)
      end

      it 'assigns column metadata' do
        get :column_data, format: 'xml', ids: [1, 2],
          column_names: %w(subject status estimated_hours done_ratio)

        expect(assigns(:columns_meta)).to have_key('group_sums')
        expect(assigns(:columns_meta)).to have_key('total_sums')

        expect(assigns(:columns_meta)['total_sums'].size).to eq(4)
        expect(assigns(:columns_meta)['total_sums'][2]).to eq(10.0)
        expect(assigns(:columns_meta)['total_sums'][3]).to eq(66)
      end

      it 'renders the column_data template' do
        get :column_data, format: 'xml', ids: [1, 2], column_names: %w(subject status estimated_hours)
        expect(response).to render_template('api/v3/work_packages/column_data', formats: %w(api))
      end
    end
  end

end
