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

RSpec.describe WorkPackages::CreateNoteContract do
  include_context "ModelContract shared context"

  let(:project) { build_stubbed(:project) }
  let(:work_package) do
    # As we only want to test the contract, we mock checking whether the work_package is valid
    wp = build_stubbed(:work_package, project:)
    # we need to clear the changes information because otherwise the
    # contract will complain about all the changes to read_only attributes
    wp.send(:clear_changes_information)

    wp
  end
  let(:user) { build_stubbed(:user) }
  let(:permissions) { %i[add_work_package_comments add_internal_comments] }

  before do
    mock_permissions_for(user) do |mock|
      mock.allow_in_project(*permissions, project:)
    end
  end

  subject(:contract) do
    described_class.new(work_package, user)
  end

  describe "validations" do
    describe "journal_notes" do
      before do
        work_package.journal_notes = "blubs"
      end

      context "if the user has only the add_work_package_comments permission" do
        let(:permissions) { %i[add_work_package_comments] }

        it_behaves_like "contract is valid"
      end

      context "if the user has only the edit_work_packages permission" do
        let(:permissions) { %i[edit_work_packages] }

        it_behaves_like "contract is valid"
      end

      context "if the user lacks the permissions" do
        let(:permissions) { [] }

        it_behaves_like "contract is invalid", journal_notes: :error_unauthorized
      end
    end

    describe "journal_internal", with_ee: [:internal_comments] do
      before do
        # Setting the journal_notes to not trigger a :blank error
        work_package.journal_notes = "blubs"
        # Enable internal comments on project
        allow(project).to receive(:enabled_internal_comments).and_return(true)
      end

      context "and journal_internal is true" do
        before do
          work_package.journal_internal = true
        end

        it_behaves_like "contract is valid"

        context "and the enterprise token does not allow internal comments", with_ee: [] do
          it "invalidates the contract, and shows the least required enterprise plan" do
            expect(contract.validate).to be(false)

            expect(contract.errors.full_messages)
              .to eq(["Internal Journal requires at least the Professional enterprise plan."])
          end
        end

        context "and the project setting does not allow internal comments" do
          before do
            allow(project).to receive(:enabled_internal_comments).and_return(false)
          end

          it_behaves_like "contract is invalid", journal_internal: :feature_disabled_for_project
        end
      end

      context "and journal_internal is false" do
        before do
          work_package.journal_internal = false
        end

        it_behaves_like "contract is valid"
      end

      context "with journal_internal is true, but lacking permissions" do
        let(:permissions) { super() - [:add_internal_comments] }

        before do
          work_package.journal_internal = true
        end

        it_behaves_like "contract is invalid", journal_internal: :error_unauthorized
      end

      context "with journal_internal is false and lacking permissions" do
        let(:permissions) { super() - [:add_internal_comments] }

        before do
          work_package.journal_internal = false
        end

        it_behaves_like "contract is valid"
      end
    end

    describe "another attribute of work package" do
      before do
        work_package.subject = "blubs"
      end

      it_behaves_like "contract is invalid", subject: :error_readonly
    end

    describe "with the work package already being invalid" do
      before do
        work_package.done_ratio = -100

        # Otherwise, the contract would complain about changing a read-only attribute
        work_package.send(:clear_changes_information)

        work_package.journal_notes = "abc"
      end

      it_behaves_like "contract is valid"
    end
  end
end
