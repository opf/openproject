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

RSpec.describe WorkPackageTypes::CopyConfiguration::DefaultsService do
  shared_let(:admin) { create(:admin) }

  let(:type) { create(:type) }

  subject(:service_call) { described_class.new(type:, user: admin).call(source:) }

  describe "#call" do
    context "with a source" do
      let(:source) do
        create(:type,
               patterns: { subject: { blueprint: "Copied {{id}}", enabled: true } },
               description: "Copied default description")
      end

      it "copies the source's subject patterns onto the type" do
        expect(service_call).to be_success
        expect(type.reload.patterns.subject.blueprint).to eq("Copied {{id}}")
      end

      it "copies the source's default description onto the type" do
        expect(service_call).to be_success
        expect(type.reload.description).to eq("Copied default description")
      end
    end

    context "when the source resolves through a link", with_flag: { subtypes: true } do
      let(:owner) { create(:type, patterns: { subject: { blueprint: "Inherited {{id}}", enabled: true } }) }
      let(:source) { create(:type) }

      before { source.link!(Type::ConfigurationLink::DEFAULTS, source: owner) }

      it "adopts the resolved owner's patterns" do
        expect(service_call).to be_success
        expect(type.reload.patterns.subject.blueprint).to eq("Inherited {{id}}")
      end
    end

    context "with an invalid source" do
      let(:source) { nil }

      it "fails without changing the type" do
        expect(service_call).not_to be_success
      end
    end

    context "when the source is the type itself" do
      let(:source) { type }

      it "fails" do
        expect(service_call).not_to be_success
      end
    end
  end
end
