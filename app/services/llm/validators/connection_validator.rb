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

module Llm
  module Validators
    # The health report for an LLM connection.
    #
    # Nothing here reads User.current: the whole report has to be reproducible
    # from a background job, which is what lets the same code answer both the
    # administrator's "Run checks" and the scheduled re-check.
    class ConnectionValidator < HealthReports::Validator
      register_group ConfigurationValidator

      register_group ServerValidator,
                     precondition: ->(_, report) { report.group(:configuration).non_failure? }

      # Costs a real completion, so it is not part of the scheduled run.
      register_group InferenceValidator,
                     precondition: lambda { |connection, report|
                       connection.deep_health_check? && report.group(:configuration).non_failure?
                     }

      register_group ModelValidator
      register_group FeatureValidator
    end
  end
end
