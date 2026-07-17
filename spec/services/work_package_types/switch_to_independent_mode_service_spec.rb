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

RSpec.describe WorkPackageTypes::SwitchToIndependentModeService do
  let(:user) { create(:admin) }
  let(:type) { create(:type) }

  subject(:service) { described_class.new(type:, aspect:, user:) }

  describe "#call" do
    context "with the copy mode" do
      let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

      it "copies the linked source's configuration and severs the link" do
        source = create(:type)
        source.pdf_export_templates.disable_all
        source.save!
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.export_templates_disabled).to eq(source.export_templates_disabled)
      end
    end

    context "with the default mode (form configuration)" do
      let(:aspect) { Type::ConfigurationLink::FORM_CONFIGURATION }

      it "resets to the administrator default groups and severs the link" do
        source = create(:type)
        source.attribute_groups = [["custom group", %w[assignee]]]
        source.save!
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::DEFAULT)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.attribute_groups.map(&:key)).to eq(Type.new.attribute_groups.map(&:key))
      end
    end

    context "with the empty mode (patterns)" do
      let(:aspect) { Type::ConfigurationLink::PATTERNS }

      it "clears the configuration and severs the link" do
        source = create(:type, patterns: { subject: { blueprint: "X {{id}}", enabled: true } })
        type.link!(aspect, source:)

        result = service.call(mode: WorkPackageTypes::IndependentMode::EMPTY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.patterns.to_h).to be_empty
      end
    end

    context "with the empty mode (pdf export)" do
      let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

      it "clears the configuration and severs the link" do
        type.pdf_export_templates.disable_all
        type.save!
        type.link!(aspect, source: create(:type))

        result = service.call(mode: WorkPackageTypes::IndependentMode::EMPTY)

        expect(result).to be_success
        expect(type.reload).not_to be_linked(aspect)
        expect(type.read_attribute(:pdf_export_templates_config)).to be_blank
      end
    end

    context "with a mode not available for the aspect" do
      let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

      it "fails and leaves the link untouched" do
        type.link!(aspect, source: create(:type))

        result = service.call(mode: WorkPackageTypes::IndependentMode::DEFAULT)

        expect(result).not_to be_success
        expect(type.reload).to be_linked(aspect)
      end
    end

    context "when the seed fails" do
      let(:aspect) { Type::ConfigurationLink::PATTERNS }

      it "leaves the link untouched" do
        allow_any_instance_of(WorkPackageTypes::CopyConfiguration::PatternsService) # rubocop:disable RSpec/AnyInstance
          .to receive(:call).and_return(ServiceResult.failure(result: type))
        type.link!(aspect, source: create(:type))

        result = service.call(mode: WorkPackageTypes::IndependentMode::COPY)

        expect(result).not_to be_success
        expect(type.reload).to be_linked(aspect)
      end
    end
  end
end
