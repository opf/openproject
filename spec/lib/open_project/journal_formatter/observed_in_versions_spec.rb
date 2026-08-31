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

RSpec.describe OpenProject::JournalFormatter::ObservedInVersions do
  describe "#render" do
    let(:version) { build_stubbed(:version, name: "Alpha") }
    let(:other_version) { build_stubbed(:version, name: "Beta") }
    let(:work_package) { build_stubbed(:work_package) }
    let(:journal) { build_stubbed(:work_package_journal, journable: work_package) }
    let(:instance) { described_class.new(journal) }
    # Unlike target versions, observed in versions has no single-value fallback
    # label: the attribute never had a singular predecessor.
    let(:label) { "<strong>Observed in versions</strong>" }

    before do
      allow(Version).to receive(:find_by).and_return(nil)

      [version, other_version].each do |v|
        allow(Version).to receive(:find_by).with(id: v.id).and_return(v)
        # Withholding names from readers outside the project is covered in the
        # JournalFormatter::NamedAssociation spec.
        allow(v).to receive(:visible?).and_return(true)
      end
    end

    context "when setting observed in versions" do
      it "renders the version names as the new value" do
        expect(instance.render(:observed_in_versions, [nil, "#{version.id},#{other_version.id}"]))
          .to eq(I18n.t(:text_journal_set_to, label:, value: "<i>Alpha, Beta</i>"))
      end
    end

    context "when changing observed in versions" do
      it "renders the old and new version names" do
        expect(instance.render(:observed_in_versions, [version.id.to_s, other_version.id.to_s]))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label:,
                        linebreak: nil,
                        old: "<i>Alpha</i>",
                        new: "<i>Beta</i>"))
      end
    end

    context "when removing all observed in versions" do
      it "renders the old version names as deleted" do
        expect(instance.render(:observed_in_versions, ["#{version.id},#{other_version.id}", nil]))
          .to eq(I18n.t(:text_journal_deleted, label:, old: "<strike><i>Alpha, Beta</i></strike>"))
      end
    end

    context "with a version that no longer exists" do
      it "renders only the existing version names" do
        expect(instance.render(:observed_in_versions, [nil, "#{version.id},99999"]))
          .to eq(I18n.t(:text_journal_set_to, label:, value: "<i>Alpha</i>"))
      end
    end

    context "with html: false" do
      it "renders plain text" do
        expect(instance.render(:observed_in_versions, [version.id.to_s, other_version.id.to_s], html: false))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "Observed in versions",
                        linebreak: nil,
                        old: "Alpha",
                        new: "Beta"))
      end
    end
  end
end
