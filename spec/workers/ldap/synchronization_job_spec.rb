#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Ldap::SynchronizationJob, type: :model do
  let!(:auth_source) { create(:ldap_auth_source) }

  let(:job) { described_class.new }
  let(:service) { instance_double(Ldap::SynchronizeUsersService) }

  before do
    allow(Ldap::SynchronizeUsersService).to receive(:new).and_return(service)
    allow(service).to receive(:call)

    job.perform
  end

  context "with user synchronization enabled (default)" do
    it "runs the sync" do
      expect(service).to have_received(:call)
    end
  end

  context "with user synchronization disabled", with_config: {
    "ldap_users_disable_sync_job" => true
  } do
    it "does not run the sync" do
      expect(service).not_to have_received(:call)
    end
  end
end
