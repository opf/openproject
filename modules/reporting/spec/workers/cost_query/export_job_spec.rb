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

RSpec.describe CostQuery::ExportJob do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }

  let(:initial_filter_params) do
    {
      project_context: project.id,
      operators: {
        user_id: "=", spent_on: ">d", project_id: "="
      },
      values: {
        user_id: ["me"], spent_on: ["2024-03-30", ""], project_id: [project.id.to_s]
      }
    }
  end

  before do
    mock_permissions_for(user, &:allow_everything)
  end

  # Performs a cost export with the given extra filters.
  #
  # @param extra_filters [Hash] A hash of attribute names and operator/value
  # pairs to add to the filter.
  # Example: `{ custom_field_17: ["=", "value"], user_id: ["=", "me"]}`
  def perform_cost_export(extra_filters: {})
    query = initial_filter_params.deep_dup
    extra_filters.each do |attribute_name, operator_and_value|
      operator, value = operator_and_value
      query[:operators][attribute_name] = operator
      query[:values][attribute_name] = value
    end
    job = described_class.new(
      export: CostQuery::Export.create,
      user:,
      mime_type: :xls,
      query:,
      project:,
      cost_types: [-1, 0]
    )
    job.perform_now
    job
  end

  RSpec::Matchers.define :have_one_attachment_with_content_type do |expected_content_type|
    def attachments(export_job)
      export_job.status_reference.attachments
    end

    match do |export_job|
      attachments_content_types = attachments(export_job).pluck(:content_type)
      attachments_content_types == [expected_content_type]
    end

    failure_message do |export_job|
      attachments_content_types = attachments(export_job).pluck(:content_type)
      "expected that #{actual} would have one attachment with mime type #{expected.inspect}, " \
        "got #{attachments_content_types.inspect} instead"
    end
  end

  it "generates an XLS export successfully" do
    job = perform_cost_export

    expect(job.job_status).to be_success, job.job_status.message
    expect(job).to have_one_attachment_with_content_type("application/vnd.ms-excel")
  end

  context "when filtering with a work package custom field" do
    it "generates an XLS report successfully" do
      custom_field = create(:string_wp_custom_field)
      job = perform_cost_export(extra_filters: { custom_field.attribute_name => ["=", ""] })

      expect(job.job_status).to be_success, job.job_status.message
      expect(job).to have_one_attachment_with_content_type("application/vnd.ms-excel")
    end
  end

  context "when filtering with a work package custom field defined after having exported once (Bug #54500)" do
    it "generates an XLS report successfully" do
      job = perform_cost_export
      expect(job.job_status).to be_success, job.job_status.message

      # Do it again with a custom field. This is to simulate the bug #54500
      # where the filter for the custom field is not found because they have
      # already been built up and cached.
      custom_field = create(:string_wp_custom_field)
      second_job = perform_cost_export(extra_filters: { custom_field.attribute_name => ["=", ""] })

      expect(second_job.job_status).to be_success, second_job.job_status.message
      expect(second_job).to have_one_attachment_with_content_type("application/vnd.ms-excel")
    end
  end
end
