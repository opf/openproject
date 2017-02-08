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

describe ::API::V3::UpdateQueryFromV3ParamsService,
         type: :model do

  let(:user) { FactoryGirl.build_stubbed(:user) }
  let(:query) { FactoryGirl.build_stubbed(:query) }

  let(:params) { double('params') }
  let(:parsed_params) { double('parsed_params') }

  let(:mock_parse_query_service) do
    mock = double('ParseQueryParamsService')

    allow(mock)
      .to receive(:call)
      .with(params)
      .and_return(mock_parse_query_service_response)

    mock
  end

  let(:mock_parse_query_service_response) do
    ServiceResult.new(success: mock_parse_query_service_success,
                      errors: mock_parse_query_service_errors,
                      result: mock_parse_query_service_result)
  end

  let(:mock_parse_query_service_success) { true }
  let(:mock_parse_query_service_errors) { nil }
  let(:mock_parse_query_service_result) { parsed_params }

  let(:mock_update_query_service) do
    mock = double('UpdateQueryFromParamsService')

    allow(mock)
      .to receive(:call)
      .with(parsed_params)
      .and_return(mock_update_query_service_response)

    mock
  end

  let(:mock_update_query_service_response) do
    ServiceResult.new(success: mock_update_query_service_success,
                      errors: mock_update_query_service_errors,
                      result: mock_update_query_service_result)
  end

  let(:mock_update_query_service_success) { true }
  let(:mock_update_query_service_errors) { nil }
  let(:mock_update_query_service_result) { query }

  let(:instance) { described_class.new(query, user) }

  before do
    allow(UpdateQueryFromParamsService)
      .to receive(:new)
      .with(query, user)
      .and_return(mock_update_query_service)
    allow(::API::V3::ParseQueryParamsService)
      .to receive(:new)
      .with(no_args)
      .and_return(mock_parse_query_service)
  end

  describe '#call' do
    subject { instance.call(params) }

    it 'returns the update result' do
      is_expected
        .to eql(mock_update_query_service_response)
    end

    context 'when parsing fails' do
      let(:mock_parse_query_service_success) { false }
      let(:mock_parse_query_service_errors) { double 'error' }
      let(:mock_parse_query_service_result) { nil }

      it 'returns the parse result' do
        is_expected
          .to eql(mock_parse_query_service_response)
      end
    end
  end
end
