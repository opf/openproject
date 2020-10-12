#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe OpenProject::JournalFormatter::CustomField do
  include CustomFieldsHelper
  include ActionView::Helpers::TagHelper

  let(:klass) { OpenProject::JournalFormatter::CustomField }
  let(:instance) { klass.new(journal) }
  let(:id) { 1 }
  let(:journal) do
    OpenStruct.new(id: id)
  end
  let(:custom_field) do
    FactoryBot.build_stubbed(:work_package_custom_field).tap do |cf|
      allow(CustomField)
        .to receive(:find_by)
        .with(id: cf.id)
        .and_return(cf)
    end
  end
  let(:key) { "custom_fields_#{custom_field.id}" }

  describe '#render' do
    describe 'WITH the first value being nil, and the second a valid value as string' do
      let(:values) { [nil, '1'] }
      let(:formatted_value) { format_value(values.last, custom_field) }

      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>#{custom_field.name}</strong>",
               value: "<i title=\"#{formatted_value}\">#{formatted_value}</i>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end

    describe 'WITH the first value being a valid value as a string, and the second being a valid value as a string' do
      let(:values) { %w[0 1] }
      let(:old_formatted_value) { format_value(values.first, custom_field) }
      let(:new_formatted_value) { format_value(values.last, custom_field) }

      let(:expected) do
        I18n.t(:text_journal_changed,
               label: "<strong>#{custom_field.name}</strong>",
               old: "<i title=\"#{old_formatted_value}\">#{old_formatted_value}</i>",
               new: "<i title=\"#{new_formatted_value}\">#{new_formatted_value}</i>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end

    describe 'WITH the first value being a valid value as a string, and the second being nil' do
      let(:values) { ['0', nil] }
      let(:formatted_value) { format_value(values.first, custom_field) }

      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>#{custom_field.name}</strong>",
               old: "<strike><i title=\"#{formatted_value}\">#{formatted_value}</i></strike>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end

    describe "WITH the first value being nil, and the second a valid value as string
              WITH no html requested" do
      let(:values) { [nil, '1'] }

      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: custom_field.name,
               value: format_value(values.last, custom_field))
      end

      it { expect(instance.render(key, values, no_html: true)).to eq(expected) }
    end

    describe "WITH the first value being a valid value as a string, and the second being a valid value as a string
              WITH no html requested" do
      let(:values) { %w[0 1] }

      let(:expected) do
        I18n.t(:text_journal_changed_plain,
               label: custom_field.name,
               old: format_value(values.first, custom_field),
               new: format_value(values.last, custom_field))
      end

      it { expect(instance.render(key, values, no_html: true)).to eq(expected) }
    end

    describe "WITH the first value being a valid value as a string, and the second being nil
              WITH no html requested" do
      let(:values) { ['0', nil] }

      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: custom_field.name,
               old: format_value(values.first, custom_field))
      end

      it { expect(instance.render(key, values, no_html: true)).to eq(expected) }
    end

    describe "WITH the first value being nil, and the second a valid value as string
              WITH the custom field being deleted" do
      let(:values) { [nil, '1'] }
      let(:key) { 'custom_values0' }

      let(:expected) do
        I18n.t(:text_journal_set_to,
               label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
               value: "<i title=\"#{values.last}\">#{values.last}</i>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end

    describe "WITH the first value being a valid value as a string, and the second being a valid value as a string
              WITH the custom field being deleted" do
      let(:values) { %w[0 1] }
      let(:key) { 'custom_values0' }

      let(:expected) do
        I18n.t(:text_journal_changed,
               label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
               old: "<i title=\"#{values.first}\">#{values.first}</i>",
               new: "<i title=\"#{values.last}\">#{values.last}</i>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end

    describe "WITH the first value being a valid value as a string, and the second being nil
              WITH the custom field being deleted" do
      let(:values) { ['0', nil] }
      let(:key) { 'custom_values0' }

      let(:expected) do
        I18n.t(:text_journal_deleted,
               label: "<strong>#{I18n.t(:label_deleted_custom_field)}</strong>",
               old: "<strike><i title=\"#{values.first}\">#{values.first}</i></strike>")
      end

      it { expect(instance.render(key, values)).to eq(expected) }
    end

    context 'for a multi list cf' do
      let(:custom_field) do
        FactoryBot.build_stubbed(:list_wp_custom_field, multi_value: true).tap do |cf|
          allow(CustomField)
            .to receive(:find_by)
            .with(id: cf.id)
            .and_return(cf)

          cf_options = double('custom_options')
          old_options = double('selected options')
          new_options = double('selected options')

          allow(cf)
            .to receive(:custom_options)
            .and_return cf_options

          allow(cf_options)
            .to receive(:where)
            .with(id: [1, 2])
            .and_return old_options

          allow(cf_options)
            .to receive(:where)
            .with(id: [3, 4])
            .and_return new_options

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
      end
      let(:old_custom_option_names) { [[1, 'cf 1'], [2, 'cf 2']] }
      let(:new_custom_option_names) { [[3, 'cf 3'], [4, 'cf 4']] }

      describe "WITH the first value being a comma separated list of ids, and the second being a comma separated list of ids" do
        let(:values) { %w[1,2 3,4] }

        let(:expected) do
          I18n.t(:text_journal_changed,
                 label: "<strong>#{custom_field.name}</strong>",
                 old: "<i title=\"cf 1, cf 2\">cf 1, cf 2</i>",
                 new: "<i title=\"cf 3, cf 4\">cf 3, cf 4</i>")
        end

        it { expect(instance.render(key, values)).to eq(expected) }
      end

      describe "WITH the first value being a comma separated list of ids, and the second being a comma separated list of ids that no longer exist" do
        let(:values) { %w[1,2 3,4] }
        let(:new_custom_option_names) { [[4, 'cf 4']] }

        let(:expected) do
          I18n.t(:text_journal_changed,
                 label: "<strong>#{custom_field.name}</strong>",
                 old: "<i title=\"cf 1, cf 2\">cf 1, cf 2</i>",
                 new: "<i title=\"(deleted option), cf 4\">(deleted option), cf 4</i>")
        end

        it { expect(instance.render(key, values)).to eq(expected) }
      end
    end
  end
end
