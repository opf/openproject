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
  let(:source) { create(:type) }
  let(:aspect) { Type::ConfigurationLink::PDF_EXPORT }

  subject(:service) { described_class.new(type:, aspect:, user:) }

  describe "#call" do
    it "removes an existing link" do
      create(:type_configuration_link, type:, source:, aspect:)

      result = service.call

      expect(result).to be_success
      expect(type.reload).not_to be_linked(aspect)
    end

    it "is a no-op when already independent" do
      result = service.call

      expect(result).to be_success
      expect(type).not_to be_linked(aspect)
    end

    context "when adopting a source" do
      subject(:service) { described_class.new(type:, aspect: Type::ConfigurationLink::PATTERNS, user:) }

      it "copies the source's config onto the type once and creates no link" do
        configured = create(:type, patterns: { subject: { blueprint: "Adopt {{id}}", enabled: true } })

        result = service.call(source: configured)

        expect(result).to be_success
        expect(type).not_to be_linked(Type::ConfigurationLink::PATTERNS)
        expect(type.reload.patterns.subject.blueprint).to eq("Adopt {{id}}")
      end

      it "leaves the link when the adoption copy fails" do
        allow_any_instance_of(WorkPackageTypes::CopyConfiguration::PatternsService) # rubocop:disable RSpec/AnyInstance
          .to receive(:call).and_return(ServiceResult.failure(result: type))
        create(:type_configuration_link, type:, source:, aspect: Type::ConfigurationLink::PATTERNS)

        result = service.call(source:)

        expect(result).not_to be_success
        expect(type.reload).to be_linked(Type::ConfigurationLink::PATTERNS)
      end
    end
  end
end
