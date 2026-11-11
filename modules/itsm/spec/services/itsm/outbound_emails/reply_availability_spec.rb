# frozen_string_literal: true

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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe ITSM::OutboundEmails::ReplyAvailability, with_flag: { helpdesk: true } do
  let(:enabled_module_names) { %i[work_package_tracking helpdesk] }
  let(:permissions) { %i[view_work_packages add_work_package_comments] }
  let(:project) { create(:project, enabled_module_names:) }
  let(:work_package) { create(:work_package, project:) }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }
  let!(:thread) { create(:itsm_email_thread, work_package:) }
  let!(:mailbox) { create(:itsm_outgoing_mailbox, project:) }

  subject(:availability) { described_class.new(work_package:, user:) }

  it { is_expected.to be_available }

  context "when the feature flag is inactive", with_flag: { helpdesk: false } do
    it { is_expected.not_to be_available }
  end

  context "when the project does not use the help desk" do
    let(:enabled_module_names) { %i[work_package_tracking] }

    it { is_expected.not_to be_available }
  end

  context "when the user may not comment" do
    let(:permissions) { %i[view_work_packages] }

    it { is_expected.not_to be_available }
  end

  context "when the work package was not created from an email" do
    let!(:thread) { nil }

    it { is_expected.not_to be_available }
  end

  context "when the project has no outgoing mailbox" do
    let!(:mailbox) { nil }

    it { is_expected.not_to be_available }
  end
end
