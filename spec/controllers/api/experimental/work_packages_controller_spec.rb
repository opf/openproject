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

describe Api::Experimental::WorkPackagesController, :type => :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:type) { FactoryGirl.create(:type_standard) }
  let(:project_1) { FactoryGirl.create(:project,
                                       types: [type]) }
  let(:project_2) { FactoryGirl.create(:project,
                                       types: [type],
                                       is_public: false) }
  let(:role) { FactoryGirl.create(:role,
                                    permissions: [:view_work_packages,
                                                  :add_work_packages,
                                                  :edit_work_packages,
                                                  :move_work_packages,
                                                  :delete_work_packages]) }
  let(:member) { FactoryGirl.create(:member,
                                      project: project_1,
                                      principal: user,
                                      roles: [role]) }
  let(:status_1) { FactoryGirl.create(:status) }
  let(:work_package_1) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            status: status_1,
                                            project: project_1) }
  let(:work_package_2) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            status: status_1,
                                            project: project_1) }
  let(:work_package_3) { FactoryGirl.create(:work_package,
                                            author: user,
                                            type: type,
                                            status: status_1,
                                            project: project_2) }
  let(:query_1) { FactoryGirl.create(:query,
                                     project: project_1) }


  let(:current_user) { FactoryGirl.create(:admin) }

  before do
    member
    allow(User).to receive(:current).and_return(current_user)
  end

  describe '#index' do
    context 'with no work packages available' do
      it 'assigns an empty work packages array' do
        get 'index', format: 'xml'
        expect(assigns(:work_packages)).to eq([])

        # expect(assigns(:allowed_statuses)).to eq([])
      end

      it 'renders the index template' do
        get 'index', format: 'xml'
        expect(response).to render_template('api/experimental/work_packages/index', formats: %w(api))
      end

      it 'assigns a query which has the default filter arguments set' do
        expected_query = Query.new
        expect(Query).to receive(:new).with(anything, initialize_with_default_filter: true)
                                      .and_return(expected_query)

        get 'index', format: 'xml'

        expect(assigns(:query)).to eql expected_query
      end

      %w(group_by c fields f sort is_public name page per_page display_sums).each do |filter_param|
        it "assigns a query which does not have the default filter arguments set if the #{filter_param} argument is provided" do
          expected_query = Query.new
          expect(Query).to receive(:new).with(anything, initialize_with_default_filter: false)
                                        .and_return(expected_query)

          get 'index', format: 'xml', filter_param => double('anything', to_i: 1).as_null_object

          expect(assigns(:query)).to eql expected_query
        end
      end
    end

    context 'with work packages' do
      let(:query) { FactoryGirl.build_stubbed(:query).tap(&:add_default_filter) }

      before do
        # FIXME: find a better solution does not involve reaching into the internals
        allow(controller).to receive(:retrieve_query).and_return(query)
        query.stub_chain(:results, :work_packages, :page, :per_page, :changed_since, :all).and_return(work_packages)
        query.stub_chain(:results, :work_package_count_by_group).and_return([])
        query.stub_chain(:results, :column_total_sums).and_return([])
        query.stub_chain(:results, :column_group_sums).and_return([])
        query.stub_chain(:results, :total_sum_of).and_return(2)
        query.stub_chain(:results, :total_entries).and_return([])

        # FIXME: METADATA TOO TRICKY TO DEAL WITH
        allow(controller).to receive(:set_work_packages_meta_data)
      end

      context 'with project_1 work packages' do
        let(:work_packages) { [ work_package_1, work_package_2, work_package_3 ] }

        it 'assigns work packages array + actions' do
          get 'index', format: 'xml', query_id: query_1.id, project_id: project_1.id

          expect(assigns(:work_packages).size).to eq(2)

          expect(assigns(:can).allowed?(work_package_1, :edit)).to be_truthy
          expect(assigns(:can).allowed?(work_package_1, :log_time)).to be_truthy
          expect(assigns(:can).allowed?(work_package_1, :move)).to be_truthy
          expect(assigns(:can).allowed?(work_package_1, :copy)).to be_truthy
          expect(assigns(:can).allowed?(work_package_1, :delete)).to be_truthy
        end
      end

      context 'with default query' do
        let(:work_packages) { [ work_package_1, work_package_2, work_package_3 ] }

        it 'assigns work packages array + actions' do
          get 'index', format: 'xml'

          expect(assigns(:work_packages).size).to eq(3)
          expect(assigns(:project)).to be_nil
        end
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
        expect(response).to render_template('api/experimental/work_packages/column_data', formats: %w(api))
      end
    end
  end

end
