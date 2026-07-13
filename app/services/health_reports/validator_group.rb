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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module HealthReports
  class ValidatorGroup
    class << self
      def call(subject)
        new(subject).call
      end

      def key = raise SubclassResponsibilityError
    end

    attr_reader :subject

    def initialize(subject)
      @subject = subject
      @group = HealthReport::ResultGroup.new(key: self.class.key)
      @pending_checks = []
    end

    def call
      catch :interrupted do
        validate
      end

      @pending_checks.each { @group.results << HealthReport::Result.skipped(it) }

      @group
    end

    private

    def validate = raise SubclassResponsibilityError

    def register_checks(*keys)
      @pending_checks.concat(keys)
    end

    def add_result(key, result)
      @group.results << result
      @pending_checks.delete(key)
    end

    def pass_check(key)
      add_result(key, HealthReport::Result.success(key))
    end

    def fail_check(key, code, context: nil)
      add_result(key, HealthReport::Result.failure(key, code, context))
      throw :interrupted
    end

    def warn_check(key, code, context: nil, halt_validation: false)
      add_result(key, HealthReport::Result.warning(key, code, context))
      throw :interrupted if halt_validation
    end
  end
end
