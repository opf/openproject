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

require "spec_helper"
require_module_spec_helper

module HealthReports
  class TestValidator < Validator
    def self.reset_groups!
      @validation_groups = nil
    end
  end
end

RSpec.describe HealthReports::Validator do
  let(:successful_validator_group) do
    class_double HealthReports::ValidatorGroup, key: :very_successful,
                                                call: instance_double(HealthReport::ResultGroup, key: :very_successful,
                                                                                                 success?: true,
                                                                                                 warning?: false,
                                                                                                 non_failure?: true,
                                                                                                 failure?: false)
  end
  let(:warning_validator_group) do
    class_double HealthReports::ValidatorGroup, key: :very_warning,
                                                call: instance_double(HealthReport::ResultGroup, key: :very_warning,
                                                                                                 success?: false,
                                                                                                 warning?: true,
                                                                                                 non_failure?: true,
                                                                                                 failure?: false)
  end
  let(:validated_subject) do
    double( # rubocop:disable RSpec/VerifiedDoubles
      "a report subject",
      health_reports: instance_double(ActiveRecord::Associations::CollectionProxy, build: HealthReport.new)
    )
  end

  subject(:validator) { HealthReports::TestValidator.new(validated_subject) }

  after do
    HealthReports::TestValidator.reset_groups!
  end

  it "returns a HealthReport" do
    expect(validator.call).to be_a(HealthReport)
  end

  it "only runs a verification if the precondition evaluates as truthy" do
    HealthReports::TestValidator.register_group warning_validator_group, precondition: ->(_, _) { false }

    report = validator.call
    expect(report.results).to be_empty
    expect(warning_validator_group).not_to have_received(:call)
  end

  it "aggregates all the results from the tests" do
    HealthReports::TestValidator.register_group successful_validator_group
    HealthReports::TestValidator.register_group warning_validator_group,
                                                precondition: ->(_, result) { result.group(:very_successful).non_failure? }

    report = HealthReports::TestValidator.new(create(:nextcloud_storage_with_local_connection)).call

    expect(report).to be_warning
    expect(report.group(:very_successful)).to be_success
    expect(report.group(:very_warning)).to be_warning
  end
end
