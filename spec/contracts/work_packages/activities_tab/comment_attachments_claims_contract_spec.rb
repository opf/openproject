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

RSpec.describe WorkPackages::ActivitiesTab::CommentAttachmentsClaimsContract do
  include_context "ModelContract shared context"

  let(:contract) { described_class.new(comment, user) }
  let(:user) { build_stubbed(:admin) }
  let(:comment) { build_stubbed(:work_package_journal, notes: "Some notes", journable: build_stubbed(:work_package)) }

  describe "validate attachment replacements" do
    describe "model assignment" do
      context "when assigned to the contract model" do
        before do
          comment.attachments_replacements = [
            build_stubbed(:attachment,
                          container: comment,
                          author: user)
          ]
        end

        it_behaves_like "contract is valid"
      end

      context "when the assigned model is different from the contract model" do
        before do
          comment.attachments_replacements = [
            build_stubbed(:attachment,
                          container: build_stubbed(:work_package),
                          author: user)
          ]
        end

        it_behaves_like "contract is invalid", attachments: :unchangeable
      end
    end

    describe "author validation" do
      context "when the attachment author is the same as the contract user" do
        before do
          comment.attachments_replacements = [
            build_stubbed(:attachment,
                          container: comment,
                          author: user)
          ]
        end

        it_behaves_like "contract is valid"
      end

      context "when the attachment author is different from the contract user" do
        before do
          comment.attachments_replacements = [
            build_stubbed(:attachment,
                          container: nil,
                          author: build_stubbed(:user))
          ]
        end

        it_behaves_like "contract is invalid", attachments: :does_not_exist
      end
    end
  end
end
