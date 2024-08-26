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

RSpec.describe OpenProject::JournalFormatter::CustomField do
  include CustomFieldsHelper
  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper
  include ActionView::Helpers::UrlHelper

  def url_helper = Rails.application.routes.url_helpers

  let(:instance) { described_class.new(journal) }
  let(:id) { 1 }
  let(:journal) { instance_double(Journal, id:) }
  let(:key) { "custom_fields_#{custom_field.id}" }
  let(:options) { {} }
  let(:custom_field) { build_stubbed(:work_package_custom_field) }

  subject(:rendered) { instance.render(key, values, **options) }

  before do
    allow(CustomField).to receive(:find_by).and_return(nil)
    allow(CustomField)
      .to receive(:find_by)
            .with(id: custom_field.id)
            .and_return(custom_field)
  end

  context "with html requested by default" do
    describe "with the first value being nil, and the second a valid value as string" do
      let(:values) { [nil, "1"] }
      let(:formatted_value) { format_value(values.last, custom_field) }

      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>#{custom_field.name}</strong>",
               value: "<i>#{formatted_value}</i>")
      end

      it { expect(rendered).to eq(expected) }
    end

    describe "with both values being valid values as strings" do
      let(:values) { %w[0 1] }
      let(:old_formatted_value) { format_value(values.first, custom_field) }
      let(:new_formatted_value) { format_value(values.last, custom_field) }

      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>#{custom_field.name}</strong>",
               linebreak: "",
               old: "<i>#{old_formatted_value}</i>",
               new: "<i>#{new_formatted_value}</i>")
      end

      it { expect(rendered).to eq(expected) }
    end

    describe "with the first value being a valid value as a string, and the second being nil" do
      let(:values) { ["0", nil] }
      let(:formatted_value) { format_value(values.first, custom_field) }

      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>#{custom_field.name}</strong>",
               old: "<strike><i>#{formatted_value}</i></strike>")
      end

      it { expect(rendered).to eq(expected) }
    end
  end

  context "with non html requested" do
    let(:options) { { html: false } }

    describe "with the first value being nil, and the second a valid value as string" do
      let(:values) { [nil, "1"] }

      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: custom_field.name,
               value: format_value(values.last, custom_field))
      end

      it { expect(rendered).to eq(expected) }
    end

    describe "with both values being valid values as strings" do
      let(:values) { %w[0 1] }

      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: custom_field.name,
               old: format_value(values.first, custom_field),
               linebreak: "",
               new: format_value(values.last, custom_field))
      end

      it { expect(rendered).to eq(expected) }
    end

    describe "with the first value being a valid value as a string, and the second being nil" do
      let(:values) { ["0", nil] }

      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: custom_field.name,
               old: format_value(values.first, custom_field))
      end

      it { expect(rendered).to eq(expected) }
    end
  end

  context "with the custom field being deleted" do
    let(:key) { "custom_fields_#{custom_field.id + 1}" }

    describe "with the first value being nil, and the second a valid value as string" do
      let(:values) { [nil, "1"] }

      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
               value: "<i>#{values.last}</i>")
      end

      it { expect(rendered).to eq(expected) }
    end

    describe "with both values being valid values as strings" do
      let(:values) { %w[0 1] }

      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
               linebreak: "",
               old: "<i>#{values.first}</i>",
               new: "<i>#{values.last}</i>")
      end

      it { expect(rendered).to eq(expected) }
    end

    describe "with the first value being a valid value as a string, and the second being nil" do
      let(:values) { ["0", nil] }

      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
               old: "<strike><i>#{values.first}</i></strike>")
      end

      it { expect(rendered).to eq(expected) }
    end
  end

  context "for a multi-select custom field" do
    let(:custom_field) { build_stubbed(:user_wp_custom_field) }

    let(:user1) { build_stubbed(:user, firstname: "Foo", lastname: "Bar") }
    let(:user2) { build_stubbed(:user, firstname: "Bla", lastname: "Blub") }
    let(:wherestub) { class_double(Principal) }
    let(:values) { [nil, "#{user1.id},#{user2.id}"] }

    before do
      allow(Principal)
        .to receive(:in_visible_project_or_me).and_return(wherestub)

      allow(wherestub)
        .to receive(:where)
              .with(id: [user1.id, user2.id])
              .and_return(visible_users)
    end

    describe "with two visible users" do
      let(:visible_users) { [user1, user2] }

      let(:formatted_value) do
        "Foo Bar, Bla Blub"
      end
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>#{custom_field.name}</strong>",
               value: "<i>#{formatted_value}</i>")
      end

      it "outputs both formatted names" do
        expect(rendered).to eq expected
      end
    end

    describe "with only one visible user" do
      let(:visible_users) { [user1] }

      let(:formatted_value) do
        "Foo Bar, (missing value or lacking permissions to access)"
      end
      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>#{custom_field.name}</strong>",
               value: "<i>#{formatted_value}</i>")
      end

      it "outputs the one visible formatted name" do
        expect(rendered).to eq expected
      end
    end
  end

  context "for a multi list custom field" do
    let(:custom_field) { build_stubbed(:list_wp_custom_field, multi_value: true) }

    let(:old_custom_option_names) { [[1, "cf 1"], [2, "cf 2"]] }
    let(:new_custom_option_names) { [[3, "cf 3"], [4, "cf 4"]] }

    before do
      cf_options = instance_double(ActiveRecord::Associations::CollectionProxy)
      old_options = instance_double(ActiveRecord::AssociationRelation)
      new_options = instance_double(ActiveRecord::AssociationRelation)

      allow(custom_field)
        .to receive(:custom_options)
              .and_return(cf_options)

      allow(cf_options)
        .to receive(:where)
              .with(id: [1, 2])
              .and_return(old_options)

      allow(cf_options)
        .to receive(:where)
              .with(id: [3, 4])
              .and_return(new_options)

      allow(old_options)
        .to receive(:order)
              .with(:position)
              .and_return(old_options)

      allow(new_options)
        .to receive(:order)
              .with(:position)
              .and_return(new_options)

      allow(old_options)
        .to receive(:pluck)
              .with(:id, :value)
              .and_return(old_custom_option_names)

      allow(new_options)
        .to receive(:pluck)
              .with(:id, :value)
              .and_return(new_custom_option_names)
    end

    describe "with both values being a comma separated list of ids" do
      let(:values) { %w[1,2 3,4] }

      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>#{custom_field.name}</strong>",
               linebreak: "",
               old: "<i>cf 1, cf 2</i>",
               new: "<i>cf 3, cf 4</i>")
      end

      it { expect(rendered).to eq(expected) }
    end

    describe "with both values being a comma separated list of ids, and second being ids that no longer exist" do
      let(:values) { %w[1,2 3,4] }
      let(:new_custom_option_names) { [[4, "cf 4"]] }

      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: "<strong>#{custom_field.name}</strong>",
               linebreak: "",
               old: "<i>cf 1, cf 2</i>",
               new: "<i>(deleted option), cf 4</i>")
      end

      it { expect(rendered).to eq(expected) }
    end
  end

  context "for a text custom field" do
    let(:custom_field) { build_stubbed(:text_wp_custom_field) }

    let(:path) do
      url_helper.diff_journal_path(id: journal.id,
                                   field: key.downcase)
    end
    let(:url) do
      url_helper.diff_journal_url(id: journal.id,
                                  field: key.downcase,
                                  protocol: Setting.protocol,
                                  host: Setting.host_name)
    end
    let(:link) { link_to(I18n.t(:label_details), path, class: "diff-details", target: "_top") }
    let(:full_url_link) { link_to(I18n.t(:label_details), url, class: "diff-details", target: "_top") }

    describe "with the first value being nil, and the second a string" do
      let(:values) { [nil, "new value"] }

      let(:expected) do
        I18n.t(:text_journal_set_with_diff,
               label: "<strong>#{custom_field.name}</strong>",
               link:)
      end

      it { expect(rendered).to be_html_eql(expected) }
    end

    describe "with both values being strings" do
      let(:values) { ["old value", "new value"] }

      let(:expected) do
        I18n.t(:text_journal_changed_with_diff,
               label: "<strong>#{custom_field.name}</strong>",
               link:)
      end

      it { expect(rendered).to be_html_eql(expected) }
    end

    describe "with the first value being a string, and the second nil" do
      let(:values) { ["old_value", nil] }

      let(:expected) do
        I18n.t(:text_journal_deleted_with_diff,
               label: "<strong>#{custom_field.name}</strong>",
               link:)
      end

      it { expect(rendered).to be_html_eql(expected) }
    end

    context "with non html requested" do
      let(:options) { { html: false } }

      describe "with both values being strings" do
        let(:values) { ["old value", "new value"] }

        let(:expected) do
          I18n.t(:text_journal_changed_with_diff,
                 label: custom_field.name,
                 link: path)
        end

        it { expect(rendered).to be_html_eql(expected) }
      end
    end

    context "with full url requested" do
      let(:options) { { only_path: false } }

      describe "with both values being strings" do
        let(:values) { ["old value", "new value"] }

        let(:expected) do
          I18n.t(:text_journal_changed_with_diff,
                 label: "<strong>#{custom_field.name}</strong>",
                 link: full_url_link)
        end

        it { expect(rendered).to be_html_eql(expected) }
      end
    end
  end
end
