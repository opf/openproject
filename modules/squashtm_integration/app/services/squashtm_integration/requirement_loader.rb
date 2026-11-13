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

module SquashTMIntegration
  class RequirementLoader
    LinkedRequirement = Data.define(:requirement, :error)
    Requirement = Data.define(:id, :name, :reference, :status, :test_cases)
    TestCase = Data.define(:id, :name, :reference, :description, :execution_status, :last_executed_on, :last_executed_by,
                           :url) do
      def executed? = !last_executed_on.nil?
    end

    def initialize(client)
      @client = client
    end

    def load_linked_requirement(squashtm_requirement_id)
      LinkedRequirement.new(requirement: fetch_requirement(squashtm_requirement_id), error: nil)
    rescue Client::NotFoundError
      LinkedRequirement.new(requirement: nil, error: :not_found)
    rescue Client::Error => e
      log_failure("requirement #{squashtm_requirement_id}", e)
      LinkedRequirement.new(requirement: nil, error: :unavailable)
    end

    def load_project_requirements(squashtm_project_id)
      client.all_requirements(squashtm_project_id)
            .map { project_requirement(it) }
            .sort_by { [it[:reference].to_s.downcase, it[:name].to_s.downcase] }
    rescue Client::Error => e
      log_failure("requirements of project #{squashtm_project_id}", e)
      nil
    end

    private

    attr_reader :client

    def fetch_requirement(squashtm_requirement_id)
      requirement = client.requirement(squashtm_requirement_id)
      version = requirement["current_version"] || {}

      Requirement.new(
        id: requirement.fetch("id"),
        name: version["name"] || requirement["name"],
        reference: version["reference"].presence,
        status: version["status"],
        test_cases: Array(version["verifying_test_cases"]).map { build_test_case(it.fetch("id")) }
      )
    end

    def build_test_case(test_case_id)
      test_case = client.test_case(test_case_id)
      latest = latest_execution(test_case_id)

      TestCase.new(
        id: test_case_id,
        name: test_case["name"],
        reference: test_case["reference"].presence,
        description: test_case["description"].presence,
        execution_status: latest&.fetch("execution_status", nil),
        last_executed_on: latest && Time.zone.parse(latest["last_executed_on"]),
        last_executed_by: latest&.fetch("last_executed_by", nil),
        url: client.test_case_url(test_case_id)
      )
    end

    def latest_execution(test_case_id)
      client.test_case_executions(test_case_id)
            .select { it["last_executed_on"].present? }
            .max_by { Time.zone.parse(it["last_executed_on"]) }
    end

    def project_requirement(requirement)
      {
        id: requirement["id"],
        name: requirement["name"],
        reference: requirement.dig("current_version", "reference").presence
      }
    end

    def log_failure(subject, error)
      Rails.logger.warn("SquashTM #{subject} could not be loaded: #{error.class}: #{error.message}")
    end
  end
end
