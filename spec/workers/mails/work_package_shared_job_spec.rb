# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 the OpenProject GmbH
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
# ++

require 'spec_helper'

RSpec.describe Mails::WorkPackageSharedJob, type: :model do
  subject(:run_job) do
    described_class.perform_now(current_user:,
                                work_package_member:)
  end

  let(:current_user) { build_stubbed(:user) }
  let(:shared_with_user) { build_stubbed(:user) }

  let(:project) { build_stubbed(:project) }
  let(:work_package) { build_stubbed(:work_package, project:) }
  let(:role) { build(:view_work_package_role) }
  let(:work_package_member) do
    build_stubbed(:work_package_member,
                  entity: work_package,
                  user: shared_with_user,
                  roles: [role])
  end

  before do
    allow(SharingMailer)
      .to receive(:shared_work_package)
            .and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: nil))
  end

  it 'sends mail' do
    run_job

    expect(SharingMailer)
      .to have_received(:shared_work_package)
            .with(current_user, work_package_member)
  end
end
