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

RSpec.describe WorkPackages::Exports::ScheduleService do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:query) { build(:query, project:, user:) }
  let(:service) { described_class.new(user:) }
  let(:captured_job_args) { {} }

  # In the service QueriesHelper#retrieve_query calls params.permit! before
  # export_list is invoked. Reproduce that precondition here so to_unsafe_h succeeds.
  def permitted(hash)
    ActionController::Parameters.new(hash).permit!
  end

  before do
    allow(WorkPackages::Export).to receive(:create).and_return(build_stubbed(:work_packages_export))
    allow(WorkPackages::ExportJob).to receive(:perform_later) do |**args|
      captured_job_args.merge!(args)
      instance_double(WorkPackages::ExportJob, job_id: "test-job-id")
    end
  end

  describe "#call — parameter safety" do
    context "when browser params include query_attributes alongside export options" do
      let(:injected_filters) { "--- \nid:\n  :operator: \"*\"\n  :values: []\n" }
      let(:browser_params) do
        permitted(
          "query_attributes" => { "filters" => injected_filters },
          "columns" => %w[id subject]
        )
      end

      it "passes query_attributes from the server, not from browser params" do
        expected_filters = Queries::WorkPackages::FilterSerializer.dump(query.filters)

        service.call(query:, mime_type: :csv, params: browser_params)

        expect(captured_job_args[:query_attributes]).to be_a(Hash)
        expect(captured_job_args[:query_attributes]["filters"]).to eq(expected_filters)
      end

      it "browser-supplied query_attributes appear only inside :options, not as a top-level job kwarg" do
        service.call(query:, mime_type: :csv, params: browser_params)

        # query_attributes should not appear in options either
        expect(captured_job_args[:options]).not_to have_key("query_attributes")
        expect(captured_job_args[:options]).not_to have_key(:query_attributes)
      end

      it "forwards permitted export options inside :options" do
        service.call(query:, mime_type: :csv, params: browser_params)

        expect(captured_job_args[:options]).to include("columns" => %w[id subject])
      end
    end

    context "when browser params include reserved job kwarg names" do
      let(:browser_params) do
        permitted(
          "user" => "myuser",
          "export" => "fake_export",
          "mime_type" => "text/csv",
          "query" => "overridden_query",
          "query_attributes" => { "filters" => "injected" }
        )
      end

      it "preserves service-set :user and :mime_type as top-level job kwargs" do
        service.call(query:, mime_type: :csv, params: browser_params)

        expect(captured_job_args[:user]).to eq(user)
        expect(captured_job_args[:mime_type]).to eq(:csv)
      end

      it "does not consume reserved names into :options", :aggregate_failures do
        service.call(query:, mime_type: :csv, params: browser_params)

        reserved = %w[user export mime_type query query_attributes]
        reserved.each do |key|
          expect(captured_job_args[:options]).not_to have_key(key), "expected #{key} to be absent from :options"
        end
      end
    end
  end
end
