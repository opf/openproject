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

describe ::API::V3::WorkPackageCollectionFromQueryParamsService,
         type: :model do
  include API::V3::Utilities::PathHelper

  let(:mock_wp_collection_from_query_service) do
    mock = double('WorkPackageCollectionFromQueryService')

    allow(mock)
      .to receive(:call)
      .with(params)
      .and_return(mock_wp_collection_service_response)

    mock
  end

  let(:mock_wp_collection_service_response) do
    ServiceResult.new(success: mock_wp_collection_service_success,
                      errors: mock_wp_collection_service_errors,
                      result: mock_wp_collection_service_result)
  end

  let(:mock_wp_collection_service_success) { true }
  let(:mock_wp_collection_service_errors) { nil }
  let(:mock_wp_collection_service_result) { double('result') }

  let(:query) { FactoryBot.build_stubbed(:query) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:user) { FactoryBot.build_stubbed(:user) }

  let(:instance) { described_class.new(user) }

  before do
    stub_const('::API::V3::WorkPackageCollectionFromQueryService',
               mock_wp_collection_from_query_service)

    allow(::API::V3::WorkPackageCollectionFromQueryService)
      .to receive(:new)
      .with(query, user, scope: nil)
      .and_return(mock_wp_collection_from_query_service)
  end

  describe '#call' do
    let(:params) { { project: project } }

    subject { instance.call(params) }

    before do
      allow(Query)
        .to receive(:new_default)
        .with(name: '_', project: project)
        .and_return(query)
    end

    it 'is successful' do
      is_expected
        .to eql(mock_wp_collection_service_response)
    end
  end
end
