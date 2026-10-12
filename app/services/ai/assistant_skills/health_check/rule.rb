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

module AI
  module AssistantSkills
    module HealthCheck
      class Rule
        MAX_EVIDENCE = 5

        def self.call(context)
          new(context).call
        end

        def self.key
          name.demodulize.underscore
        end

        attr_reader :context

        def initialize(context)
          @context = context
        end

        def call
          raise SubclassResponsibilityError
        end

        private

        def finding(severity:, area:, evidence:, **text_args)
          Finding.new(rule_key: self.class.key,
                      severity: severity.to_s,
                      area: area.to_s,
                      text: I18n.t("ai_assistance.health_check.rules.#{self.class.key}", **text_args),
                      evidence:)
        end

        def evidence_for(work_packages)
          shown = work_packages.first(MAX_EVIDENCE).map { |wp| work_package_evidence(wp) }
          rest = work_packages.size - shown.size
          shown << { "text" => I18n.t("ai_assistance.health_check.and_more", count: rest) } if rest.positive?
          shown
        end

        def work_package_evidence(record)
          {
            "text" => "#{record.formatted_id} #{record.subject} (#{record.status&.name})",
            "work_package_id" => record.id
          }
        end
      end
    end
  end
end
