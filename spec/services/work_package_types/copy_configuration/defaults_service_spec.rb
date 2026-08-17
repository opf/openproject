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

  let(:variant) { create(:type).default_variant }

  subject(:service_call) { described_class.new(variant:, user: admin).call(source:) }

  describe "#call" do
    context "with a source" do
      let(:source) do
        create(:type,
               patterns: { subject: { blueprint: "Copied {{id}}", enabled: true } },
               default_work_package_description: "Copied default description").default_variant
      end

      it "copies the source's subject patterns onto the variant" do
        expect(service_call).to be_success
        expect(variant.reload.patterns.subject.blueprint).to eq("Copied {{id}}")
      end

      it "copies the source's default work package description onto the variant" do
        expect(service_call).to be_success
        expect(variant.reload.default_work_package_description).to eq("Copied default description")
      end
    end

    context "when the source resolves through a link", with_flag: { type_variants: true } do
      let(:owner) { create(:type, patterns: { subject: { blueprint: "Inherited {{id}}", enabled: true } }).default_variant }
      let(:source) { create(:type).default_variant }

      before { link_configuration(source, source: owner, aspect: TypeVariant::DEFAULTS) }

      it "adopts the resolved owner's patterns" do
        expect(service_call).to be_success
        expect(variant.reload.patterns.subject.blueprint).to eq("Inherited {{id}}")
      end
    end

    context "with an invalid source" do
      let(:source) { nil }

      it "fails without changing the variant" do
        expect(service_call).not_to be_success
      end
    end

    context "when the source is the variant itself" do
      let(:source) { variant }

      it "fails" do
        expect(service_call).not_to be_success
      end
    end
  end
end
