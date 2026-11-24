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
  describe ".param_key" do
    it "names the wizard parameter after the variant's reference" do
      expect(described_class.param_key(Workflow)).to eq(:started_workflow_id)
      expect(described_class.param_key(FormConfiguration)).to eq(:started_form_configuration_id)
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
