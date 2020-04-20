#-- encoding: UTF-8

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

describe WorkPackagesController, type: :controller do
  before do
    login_as current_user
  end

  let(:stub_project) { FactoryBot.build_stubbed(:project, identifier: 'test_project', public: false) }
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:work_packages) { [FactoryBot.build_stubbed(:stubbed_work_package)] }

  describe 'index' do
    let(:query) do
      FactoryBot.build_stubbed(:query)
    end

    before do
      allow(User.current).to receive(:allowed_to?).and_return(true)
      allow(controller).to receive(:retrieve_query).and_return(query)
    end

    describe 'bcf' do
      let(:mime_type) { 'bcf' }
      let(:export_storage) { FactoryBot.build_stubbed(:work_packages_export) }

      before do
        service_instance = double('service_instance')

        allow(WorkPackages::Exports::ScheduleService)
          .to receive(:new)
          .with(user: current_user)
          .and_return(service_instance)

        allow(service_instance)
          .to receive(:call)
          .with(query: query, mime_type: mime_type.to_sym, params: anything)
          .and_return(ServiceResult.new(result: export_storage))
      end

      it 'redirects to the export' do
        get 'index', params: { format: 'bcf' }

        expect(response)
          .to redirect_to work_packages_export_path(export_storage.id)
      end
    end
  end
end
