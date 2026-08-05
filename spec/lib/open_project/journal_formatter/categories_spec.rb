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

RSpec.describe OpenProject::JournalFormatter::Categories do
  describe "#render" do
    let(:category) { build_stubbed(:category, name: "Alpha") }
    let(:other_category) { build_stubbed(:category, name: "Beta") }
    let(:work_package) { build_stubbed(:work_package) }
    let(:journal) { build_stubbed(:work_package_journal, journable: work_package) }
    let(:instance) { described_class.new(journal) }
    # While the multiple categories feature is inactive, the single-category
    # "Category" label used across the UI is kept.
    let(:label) { "<strong>Category</strong>" }

    before do
      allow(Category).to receive(:find_by).and_return(nil)

      [category, other_category].each do |c|
        allow(Category).to receive(:find_by).with(id: c.id).and_return(c)
      end
    end

    context "when setting categories" do
      it "renders the category names as the new value" do
        expect(instance.render(:categories, [nil, "#{category.id},#{other_category.id}"]))
          .to eq(I18n.t(:text_journal_set_to, label:, value: "<i>Alpha, Beta</i>"))
      end
    end

    context "when changing categories" do
      it "renders the old and new category names" do
        expect(instance.render(:categories, [category.id.to_s, other_category.id.to_s]))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label:,
                        linebreak: nil,
                        old: "<i>Alpha</i>",
                        new: "<i>Beta</i>"))
      end
    end

    context "when removing all categories" do
      it "renders the old category names as deleted" do
        expect(instance.render(:categories, ["#{category.id},#{other_category.id}", nil]))
          .to eq(I18n.t(:text_journal_deleted, label:, old: "<strike><i>Alpha, Beta</i></strike>"))
      end
    end

    context "with a category that no longer exists" do
      it "renders only the existing category names" do
        expect(instance.render(:categories, [nil, "#{category.id},99999"]))
          .to eq(I18n.t(:text_journal_set_to, label:, value: "<i>Alpha</i>"))
      end
    end

    context "when the multiple categories feature is active",
            with_flag: { work_package_multiple_categories: true },
            with_settings: { work_package_multiple_categories: true } do
      it "labels the change with 'Categories'" do
        expect(instance.render(:categories, [category.id.to_s, other_category.id.to_s]))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "<strong>Categories</strong>",
                        linebreak: nil,
                        old: "<i>Alpha</i>",
                        new: "<i>Beta</i>"))
      end
    end

    context "with html: false" do
      it "renders plain text" do
        expect(instance.render(:categories, [category.id.to_s, other_category.id.to_s], html: false))
          .to eq(I18n.t(:text_journal_changed_plain,
                        label: "Category",
                        linebreak: nil,
                        old: "Alpha",
                        new: "Beta"))
      end
    end
  end
end
