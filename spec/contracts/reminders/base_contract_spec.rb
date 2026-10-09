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
require "contracts/shared/model_contract_shared_context"

RSpec.describe Reminders::BaseContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(reminder, user) }
  let(:user) { build_stubbed(:admin) }
  let(:creator) { user }
  let(:reminder) { build_stubbed(:reminder, creator:) }

  before do
    User.current = user
    allow(User).to receive(:exists?).with(user.id).and_return(true)
  end

  describe "admin user" do
    it_behaves_like "contract is valid"
  end

  describe "non-admin user" do
    context "with valid permissions" do
      let(:user) { build_stubbed(:user) }

      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_work_packages, project: reminder.remindable.project)
        end
      end

      it_behaves_like "contract is valid"
    end

    context "without valid permissions" do
      let(:user) { build_stubbed(:user) }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  describe "anonymous user" do
    let(:user) { build_stubbed(:anonymous) }

    before do
      mock_permissions_for(user) do |mock|
        mock.allow_in_project(:view_work_packages, project: reminder.remindable.project)
      end
    end

    it_behaves_like "contract is invalid", base: :error_unauthorized
  end

  describe "validate creator exists" do
    context "when creator does not exist" do
      before { allow(User).to receive(:exists?).with(user.id).and_return(false) }

      it_behaves_like "contract is invalid", creator: :not_found
    end
  end

  describe "validate acting user" do
    context "when the current user is different from the remindable acting user" do
      let(:different_user) { build_stubbed(:user) }

      before do
        allow(User).to receive(:exists?).with(different_user.id).and_return(true)
        reminder.creator = different_user
      end

      it_behaves_like "contract is invalid", creator: :invalid
    end
  end

  describe "validate remindable object" do
    context "when remindable is blank" do
      before { reminder.remindable = nil }

      it_behaves_like "contract is invalid", remindable: :not_found
    end

    context "when remindable is a work package" do
      let(:work_package) { build_stubbed(:work_package) }

      before { reminder.remindable = work_package }

      it_behaves_like "contract is valid"
    end
  end

  describe "validate remind at is present" do
    context "when remind at is blank" do
      before { reminder.remind_at = nil }

      it_behaves_like "contract is invalid", remind_at: :blank
    end

    context "when remind at is present" do
      before { reminder.remind_at = 1.day.from_now }

      it_behaves_like "contract is valid"
    end
  end

  describe "validate remind at is in future" do
    context "when remind at is in the past" do
      before { reminder.remind_at = 1.day.ago }

      it_behaves_like "contract is invalid", remind_at: :datetime_must_be_in_future
    end

    context "when remind at is in the future" do
      before { reminder.remind_at = 1.day.from_now }

      it_behaves_like "contract is valid"
    end
  end

  describe "validate note length" do
    context "when note is too long" do
      before { reminder.note = "a" * (described_class::MAX_NOTE_CHARS_LENGTH + 1) }

      it_behaves_like "contract is invalid", note: :too_long
    end

    context "when note is within the limit" do
      before { reminder.note = "a" * described_class::MAX_NOTE_CHARS_LENGTH }

      it_behaves_like "contract is valid"
    end
  end

  include_examples "contract reuses the model errors"
end
