# frozen_string_literal: true

# -- copyright
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
# ++

module Backlogs
  class BucketDestroyModalComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    TEST_SELECTOR = "backlog-bucket-destroy-modal-dialog"

    attr_reader :backlog_bucket

    def initialize(backlog_bucket:)
      super()
      @backlog_bucket = backlog_bucket
    end

    private

    def title
      t(".title")
    end

    def details
      t(".details", name: backlog_bucket.name)
    end

    def form_arguments
      {
        action: project_backlogs_bucket_path(backlog_bucket.project,
                                                     backlog_bucket,
                                                     helpers.all_backlogs_params),
        method: :delete
      }
    end
  end
end
