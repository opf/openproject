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

RSpec.describe Reminders::UpdateContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(reminder, user) }
  let(:user) { build_stubbed(:admin) }
  let(:creator) { user }
  let(:reminder) { build_stubbed(:reminder, creator:) }

  before do
    User.current = user
    allow(User).to receive(:exists?).with(user.id).and_return(true)
  end

  describe "validate unchangeable attributes" do
    context "when remindable changed" do
      before do
        reminder.remindable = build_stubbed(:work_package)
      end

      it_behaves_like "contract is invalid", base: :unchangeable
    end

    context "when creator_id changed" do
      before do
        new_creator = build_stubbed(:user)
        reminder.creator = new_creator
        allow(User).to receive(:exists?).with(new_creator.id).and_return(true)
      end

      it_behaves_like "contract is invalid", base: :unchangeable
    end
  end

  include_examples "contract reuses the model errors"
end
