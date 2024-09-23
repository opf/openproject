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

module API
  module V3
    module JobStatus
      class JobStatusRepresenter < ::API::Decorators::Single
        self_link id_attribute: :job_id,
                  title_getter: ->(*) {}

        property :job_id

        property :status, getter: ->(*) { batch_aware_status }, exec_context: :decorator

        property :message,
                 render_nil: true

        property :payload,
                 render_nil: true

        def _type
          "JobStatus"
        end

        def batch_aware_status
          batch = GoodJob::Job.find_by(id: represented.job_id)&.batch
          return represented.status unless batch

          unless batch.finished?
            return "in_process" if batch.jobs.any?(&:running?)

            return "in_queue"
          end

          return "success" if batch.succeeded?

          "failure" if batch.discarded?
        end
      end
    end
  end
end
