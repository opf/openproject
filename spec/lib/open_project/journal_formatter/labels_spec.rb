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

RSpec.describe OpenProject::JournalFormatter::Labels do
  describe "#render" do
    let(:label) { build_stubbed(:label, name: "A") }
    let(:other_label) { build_stubbed(:label, name: "B") }
    let(:work_package) { build_stubbed(:work_package) }
    let(:journal) { build_stubbed(:work_package_journal, journable: work_package) }
    let(:instance) { described_class.new(journal) }
    let(:label_text) { "<strong>Labels</strong>" }

    before do
      allow(Label).to receive(:find_by).and_return(nil)

      [label, other_label].each do |l|
        allow(Label).to receive(:find_by).with(id: l.id).and_return(l)
      end
    end

    context "when setting labels" do
      it "renders the label names as the new value" do
        expect(instance.render(:labels, [nil, "#{label.id},#{other_label.id}"]))
          .to eq(I18n.t(:text_journal_set_to, label: label_text, value: "<i>A, B</i>"))
      end
    end

    context "when changing labels" do
      it "renders the old and new label names" do
        expect(instance.render(:labels, [label.id.to_s, other_label.id.to_s]))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: label_text,
                        linebreak: nil,
                        old: "<i>A</i>",
                        new: "<i>B</i>"))
      end
    end

    context "when removing all labels" do
      it "renders the old label names as deleted" do
        expect(instance.render(:labels, ["#{label.id},#{other_label.id}", nil]))
          .to eq(I18n.t(:text_journal_deleted, label: label_text, old: "<strike><i>A, B</i></strike>"))
      end
    end

    context "with a label that no longer exists" do
      it "renders only the existing label names" do
        expect(instance.render(:labels, [nil, "#{label.id},99999"]))
          .to eq(I18n.t(:text_journal_set_to, label: label_text, value: "<i>A</i>"))
      end
    end

    context "when setting labels that no longer exist" do
      it "renders no detail" do
        expect(instance.render(:labels, [nil, "99999,99998"]))
          .to eq(I18n.t(:text_journal_deleted_no_detail, label: label_text))
      end
    end

    context "with html: false" do
      it "renders plain text" do
        expect(instance.render(:labels, [label.id.to_s, other_label.id.to_s], html: false))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "Labels",
                        linebreak: nil,
                        old: "A",
                        new: "B"))
      end
    end
  end
end
