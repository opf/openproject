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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"
require "contracts/shared/model_contract_shared_context"

RSpec.describe Notifications::CreateMentionFromApiContract do
  include_context "ModelContract shared context"

  let(:project) { build_stubbed(:project) }
  let(:document) { build_stubbed(:document, project:) }
  let(:current_user) { build_stubbed(:user) }
  let(:recipient) { build_stubbed(:user) }
  let(:resource) { document }
  let(:reason) { :mentioned }
  let(:current_user_permissions) { %i[view_documents manage_documents] }
  let(:recipient_permissions) { %i[view_documents] }

  let(:notification) do
    Notification.new(recipient:,
                     reason:,
                     resource:,
                     actor: current_user,
                     read_ian: false)
  end

  let(:contract) { described_class.new(notification, current_user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*current_user_permissions, project:)
    end
    if recipient
      mock_permissions_for(recipient) do |mock|
        mock.allow_in_project(*recipient_permissions, project:)
      end
    end
  end

  describe "#validation" do
    it_behaves_like "contract is valid"

    context "with a reason other than mentioned", :check_errors_i18n do
      let(:reason) { :assigned }

      it_behaves_like "contract is invalid", reason: :inclusion
    end

    context "without a reason" do
      let(:reason) { nil }

      it_behaves_like "contract is invalid", reason: :inclusion
    end

    context "with a resource whose strategy does not opt in to API mentions", :check_errors_i18n do
      let(:resource) { build_stubbed(:work_package, project:) }

      it_behaves_like "contract is invalid", resource: :mentions_not_supported
    end

    context "with a resource without a strategy" do
      let(:resource) { build_stubbed(:project) }

      it_behaves_like "contract is invalid", resource: :mentions_not_supported
    end

    context "without a resource" do
      let(:resource) { nil }

      it_behaves_like "contract is invalid", resource: :mentions_not_supported
    end

    context "when the document is not visible to the current user" do
      let(:current_user_permissions) { [] }

      it_behaves_like "contract is invalid", base: :error_not_found
    end

    context "when the current user may view but not edit the document" do
      let(:current_user_permissions) { %i[view_documents] }

      it_behaves_like "contract user is unauthorized"
    end

    context "without a recipient" do
      let(:recipient) { nil }

      it_behaves_like "contract is invalid", recipient: :blank
    end

    context "with a locked recipient", :check_errors_i18n do
      let(:recipient) { build_stubbed(:user, status: :locked) }

      it_behaves_like "contract is invalid", recipient: :not_an_active_user
    end

    context "with a builtin recipient" do
      let(:recipient) { build_stubbed(:anonymous) }

      it_behaves_like "contract is invalid", recipient: :not_an_active_user
    end

    context "with a recipient not allowed to view the document" do
      let(:recipient_permissions) { [] }

      it_behaves_like "contract is invalid", recipient: :not_allowed
    end
  end
end
