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

##
# Create journal for the given user and note.
# Does not change the work package itself.

class AddWorkPackageNoteService
  include Contracted
  include Shared::ServiceContext

  attr_accessor :user, :work_package

  def initialize(user:, work_package:)
    self.user = user
    self.work_package = work_package
    self.contract_class = WorkPackages::CreateNoteContract
  end

  def call(notes, send_notifications: nil, internal: false)
    in_context(work_package, send_notifications:) do
      add_journal_to_work_package(notes, internal)
      success, errors = save_journal_with_validation

      journal = fetch_latest_journal if success

      build_service_result(success, journal, errors)
    end
  end

  private

  def add_journal_to_work_package(notes, internal)
    work_package.add_journal(user:, notes:, internal:)
  end

  def save_journal_with_validation
    validate_and_yield(work_package, user) do
      work_package.save_journals
    end
  end

  def fetch_latest_journal
    # In test environment, because of the difference in the way of handling transactions,
    # the journal needs to be actively loaded without SQL caching in place.
    Journal.connection.uncached do
      work_package.journals.last
    end
  end

  def build_service_result(success, result, errors)
    ServiceResult.new(success:, result:, errors:).on_success { add_attachment_claims_to(it) }
  end

  def add_attachment_claims_to(service_result)
    attachments_claims = claim_attachments_for(service_result.result)
    service_result.add_dependent!(attachments_claims)
  end

  def claim_attachments_for(journal)
    WorkPackages::ActivitiesTab::CommentAttachmentsClaims::ClaimsService
      .new(user: User.current, model: journal)
      .call
  end
end
