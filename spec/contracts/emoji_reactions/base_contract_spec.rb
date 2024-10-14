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

RSpec.describe EmojiReactions::BaseContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(emoji_reaction, user) }
  let(:user) { build_stubbed(:admin) }
  let(:emoji_reaction) { build_stubbed(:emoji_reaction, user:) }

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
          mock.allow_in_project(:add_work_package_notes, project: emoji_reaction.reactable.project)
        end
      end

      it_behaves_like "contract is valid"
    end

    context "without valid permissions" do
      let(:user) { build_stubbed(:user) }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  describe "validate user exists" do
    context "when user does not exist" do
      before { allow(User).to receive(:exists?).with(user.id).and_return(false) }

      it_behaves_like "contract is invalid", user: :error_not_found
    end
  end

  describe "validate acting user" do
    context "when the current user is different from the reactable acting user" do
      let(:different_user) { build_stubbed(:user) }

      before do
        allow(User).to receive(:exists?).with(different_user.id).and_return(true)
        emoji_reaction.user = different_user
      end

      it_behaves_like "contract is invalid", user: :error_unauthorized
    end
  end

  describe "validate reactable object" do
    context "when reactable is blank" do
      before { emoji_reaction.reactable = nil }

      it_behaves_like "contract is invalid", reactable: :error_not_found
    end

    context "when reactable is a work package" do
      let(:work_package) { build_stubbed(:work_package) }

      before { emoji_reaction.reactable = work_package }

      it_behaves_like "contract is valid"
    end

    context "when reactable is a journal" do
      let(:journal) { build_stubbed(:work_package_journal) }

      before { emoji_reaction.reactable = journal }

      it_behaves_like "contract is valid"
    end

    context "when reactable is neither a journal nor a work package" do
      let(:unknown_object) { build_stubbed(:project) }

      before { emoji_reaction.reactable = unknown_object }

      it_behaves_like "contract is invalid", base: :error_unauthorized
    end
  end

  describe "validate emoji type" do
    context "when emoji is not included in the available emojis" do
      before { emoji_reaction.emoji = "not_an_emoji" }

      it_behaves_like "contract is invalid", emoji: :inclusion
    end
  end

  include_examples "contract reuses the model errors"
end
