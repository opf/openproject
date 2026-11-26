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

require "spec_helper"

RSpec.describe WorkPackageTypes::NamedReferences::DiscardStartedService do
  describe ".params_for" do
    it "names the wizard parameter after the variant's reference" do
      expect(described_class.params_for(Workflow, 7)).to eq(started_workflow_id: 7)
      expect(described_class.params_for(FormConfiguration, 3)).to eq(started_form_configuration_id: 3)
    end

    it "carries nothing without a started one" do
      expect(described_class.params_for(Workflow, nil)).to eq({})
    end
  end

  describe ".id_in" do
    def params(**) = ActionController::Parameters.new(**)

    it "reads the id started for the reference" do
      expect(described_class.id_in(params(started_workflow_id: "7"), Workflow)).to eq(7)
      expect(described_class.id_in(params(started_workflow_id: "7"), FormConfiguration)).to be_nil
    end

    it "finds none in a blank or malformed value" do
      ["", "abc", "7abc", ["7"], { "a" => "7" }].each do |value|
        expect(described_class.id_in(params(started_workflow_id: value), Workflow)).to be_nil
      end
    end
  end

  describe ".carry_in" do
    let(:workflow) { build_stubbed(:named_workflow) }

    def query_of(url) = Rack::Utils.parse_nested_query(URI.parse(url).query)

    it "adds the started id to an address" do
      url = described_class.carry_in("/types/1/creation_wizard", workflow)

      expect(url).to start_with("/types/1/creation_wizard?")
      expect(query_of(url)).to eq("started_workflow_id" => workflow.id.to_s)
    end

    it "replaces the one started before, and keeps the rest" do
      url = described_class.carry_in(
        "/types/1/creation_wizard?step=workflows&started_workflow_id=1&started_form_configuration_id=2", workflow
      )

      expect(query_of(url)).to eq("step" => "workflows",
                                  "started_workflow_id" => workflow.id.to_s,
                                  "started_form_configuration_id" => "2")
    end
  end

  describe "#call" do
    subject(:service) { described_class.new(model_class: Workflow) }

    let!(:started) { create(:named_workflow) }

    it "discards a started one no variant uses" do
      result = service.call(started.id)

      expect(result).to be_success
      expect(Workflow).not_to exist(started.id)
    end

    it "keeps a started one a variant uses, and says why" do
      create(:type).default_variant.update!(workflow: started)

      result = service.call(started.id)

      expect(result).to be_failure
      expect(result.errors).to be_present
      expect(Workflow).to exist(started.id)
    end

    it "has nothing to discard without an id, or once it is gone" do
      expect(service.call(nil)).to be_success
      expect(service.call(started.tap(&:destroy!).id)).to be_success
    end
  end
end
