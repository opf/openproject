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

module Import
  module JobLogging
    extend ActiveSupport::Concern

    included do
      around_perform :with_job_log_context

      if include?(JobIteration::Iteration)
        on_start :log_started
        on_complete :log_finished
      else
        before_perform :log_started
        after_perform :log_finished
      end
    end

    private

    def with_log_context(context)
      logger.tagged(*log_tags(context)) do
        yield
      rescue StandardError => e
        log_failed(e)
        raise
      end
    end

    def with_job_log_context(&)
      with_log_context(log_context, &)
    end

    def log_context
      {}
    end

    def log_tags(context)
      context.compact.map { |key, value| "#{key}:#{value}" }
    end

    def log_started
      logger.info "#{log_name} started"
    end

    def log_finished
      logger.info "#{log_name} finished"
    end

    def log_failed(error)
      return if @logged_failure.equal?(error)

      @logged_failure = error
      logger.error "#{log_name} failed: #{error.message}"
    end

    def log_name
      self.class.name.demodulize
    end
  end
end
