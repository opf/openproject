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

RSpec.describe Queries::WorkPackages::Filter::LabelsFilter do
  let!(:apple) { create(:label, name: "apple") }
  let!(:zebra) { create(:label, name: "zebra") }

  it_behaves_like "basic query filter" do
    let(:class_key) { :label_id }
    let(:type) { :list_optional }
    let(:human_name) { "Labels" }

    describe "#available?" do
      it "is true with the feature flag enabled", with_flag: { work_package_labels: true } do
        expect(instance).to be_available
      end

      it "is false with the feature flag disabled", with_flag: { work_package_labels: false } do
        expect(instance).not_to be_available
      end
    end

    describe "#allowed_values" do
      it "returns a name and id pair for every label" do
        expect(instance.allowed_values)
          .to contain_exactly([apple.name, apple.id.to_s], [zebra.name, zebra.id.to_s])
      end
    end
  end

  describe "#where" do
    let!(:apple_work_package) { create(:work_package).tap { |wp| wp.labels << apple } }
    let!(:apple_zebra_work_package) { create(:work_package).tap { |wp| wp.labels << [apple, zebra] } }
    let!(:zebra_work_package) { create(:work_package).tap { |wp| wp.labels << zebra } }
    let!(:unlabeled_work_package) { create(:work_package) }

    let(:instance) { described_class.create!(operator:, values:) }

    subject { WorkPackage.where(instance.where) }

    context "for '='" do
      let(:operator) { "=" }
      let(:values) { [apple.id.to_s] }

      it { is_expected.to contain_exactly(apple_work_package, apple_zebra_work_package) }
    end

    context "for '=' with several labels" do
      let(:operator) { "=" }
      let(:values) { [apple.id.to_s, zebra.id.to_s] }

      it "matches work packages carrying any of them" do
        expect(subject).to contain_exactly(apple_work_package, apple_zebra_work_package, zebra_work_package)
      end
    end

    context "for '!'" do
      let(:operator) { "!" }
      let(:values) { [apple.id.to_s] }

      it "keeps work packages without that label, labeled or not" do
        expect(subject).to contain_exactly(zebra_work_package, unlabeled_work_package)
      end
    end

    context "for '*'" do
      let(:operator) { "*" }
      let(:values) { [] }

      it "matches every labeled work package" do
        expect(subject).to contain_exactly(apple_work_package, apple_zebra_work_package, zebra_work_package)
      end
    end

    context "for '!*'" do
      let(:operator) { "!*" }
      let(:values) { [] }

      it { is_expected.to contain_exactly(unlabeled_work_package) }
    end
  end
end
