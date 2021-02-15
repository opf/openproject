#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Principals::DeleteJob, type: :model do
  subject(:job) { described_class.perform_now(principal) }

  let(:deleted_user) do
    instance_double(DeletedUser).tap do |du|
      allow(DeletedUser)
        .to receive(:first)
        .and_return(du)
    end
  end
  let(:principal) do
    instance_double(Principal, destroy: true)
  end
  let(:service_failure) { false }
  let(:service_result) do
    instance_double(ServiceResult, failure?: service_failure)
  end
  let(:service) do
    instance = instance_double(Principals::ReplaceReferencesService)

    allow(Principals::ReplaceReferencesService)
      .to receive(:new)
      .and_return(instance)

    allow(instance)
      .to receive(:call)
      .with(from: principal, to: DeletedUser.first)
      .and_return(service_result)

    instance
  end

  describe '#perform' do
    before do
      service
      job
    end

    context 'with the service being successful' do
      it 'deletes the principal' do
        expect(principal)
          .to have_received(:destroy)
      end

      it 'calls the service' do
        expect(service)
          .to have_received(:call)
      end
    end

    context 'with the service failing' do
      let(:service_failure) { true }

      it 'does not delete the principal' do
        expect(principal)
          .not_to have_received(:destroy)
      end

      it 'calls the service' do
        expect(service)
          .to have_received(:call)
      end
    end
  end
end
