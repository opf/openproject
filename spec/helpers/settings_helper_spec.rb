#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'ostruct'

describe SettingsHelper, type: :helper do
  include Capybara::RSpecMatchers

  let(:options) { { class: 'custom-class' } }

  describe '#setting_select' do
    before do
      expect(Setting).to receive(:field).and_return('2')
    end

    subject(:output) {
      helper.setting_select :field, [['Popsickle', '1'], ['Jello', '2'], ['Ice Cream', '3']], options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'select-container'

    it 'should output element' do
      expect(output).to have_selector 'select.form--select > option', count: 3
      expect(output).to have_select 'settings_field', selected: 'Jello'
    end
  end

  describe '#setting_multiselect' do
    before do
      expect(Setting).to receive(:field).at_least(:once).and_return('1')
    end

    subject(:output) {
      helper.setting_multiselect :field, [['Popsickle', '1'], ['Jello', '2'], ['Ice Cream', '3']], options
    }

    it_behaves_like 'wrapped in container' do
      let(:container_count) { 3 }
    end

    it 'should have checkboxes wrapped in checkbox-container' do
      expect(output).to have_selector 'span.form--check-box-container', count: 3
    end

    it 'should have three labels' do
      expect(output).to have_selector 'label.form--label-with-check-box', count: 3
    end

    it 'should output element' do
      expect(output).to have_selector 'input[type="checkbox"].form--check-box', count: 3
    end
  end

  describe '#settings_matrix' do
    before do
      expect(Setting).to receive(:field_a).at_least(:once).and_return('2')
      expect(Setting).to receive(:field_b).at_least(:once).and_return('3')
    end

    subject(:output) {
      settings = [:field_a, :field_b]
      choices = [
        {
          caption: 'Popsickle',
          value: '1'
        },
        {
          caption: 'Jello',
          value: '2'
        },
        {
          caption: 'Ice Cream',
          value: '3'
        },
        {
          value: 'Quarkspeise'
        }
      ]
      helper.settings_matrix settings, choices
    }

    it_behaves_like 'not wrapped in container'

    it 'is structured as a table' do
      expect(output).to have_selector 'table.form--matrix'
    end

    it 'has table headers' do
      expect(output).to have_selector 'thead th.form--matrix-header-cell', count: 3
    end

    it 'has three table rows' do
      expect(output).to have_selector 'tbody > tr.form--matrix-row', count: 4
    end

    it 'has cells with text labels' do
      expect(output).to be_html_eql(%{
        <td class="form--matrix-cell">Popsickle</td>
      }).at_path('tr:first-child > td:first-child')
    end

    it 'has cells with styled checkboxes' do
      expect(output).to be_html_eql(%{
        <td class="form--matrix-checkbox-cell">
          <span class="form--check-box-container">
            <input class="form--check-box" id="field_a_1"
              name="settings[field_a][]" type="checkbox" value="1">
          </span>
        </td>
      }).at_path('tr.form--matrix-row:first-child > td:nth-of-type(2)')

      expect(output).to be_html_eql(%{
        <td class="form--matrix-checkbox-cell">
          <span class="form--check-box-container">
            <input class="form--check-box" id="field_a_Quarkspeise"
              name="settings[field_a][]" type="checkbox" value="Quarkspeise">
          </span>
        </td>
      }).at_path('tr.form--matrix-row:last-child > td:nth-of-type(2)')
    end

    it 'has the correct fields checked' do
      expect(output).to have_checked_field 'field_a_2'
      expect(output).to have_checked_field 'field_b_3'
    end
  end

  describe '#setting_text_field' do
    before do
      expect(Setting).to receive(:field).and_return('important value')
    end

    subject(:output) {
      helper.setting_text_field :field, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-field-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <input class="custom-class form--text-field"
          id="settings_field" name="settings[field]" type="text" value="important value" />
      }).at_path('input')
    end
  end

  describe '#setting_text_area' do
    before do
      expect(Setting).to receive(:field).and_return('important text')
    end

    subject(:output) {
      helper.setting_text_area :field, options
    }

    it_behaves_like 'labelled by default'
    it_behaves_like 'wrapped in field-container by default'
    it_behaves_like 'wrapped in container', 'text-area-container'

    it 'should output element' do
      expect(output).to be_html_eql(%{
        <textarea class="custom-class form--text-area" id="settings_field" name="settings[field]">
important text</textarea>
      }).at_path('textarea')
    end
  end

  describe '#setting_check_box' do
    subject(:output) {
      helper.setting_check_box :field, options
    }

    context 'when setting is true' do
      before do
        expect(Setting).to receive(:field?).and_return(true)
      end

      it_behaves_like 'labelled by default'
      it_behaves_like 'wrapped in field-container by default'
      it_behaves_like 'wrapped in container', 'check-box-container'

      it 'should output element' do
        expect(output).to have_selector 'input[type="checkbox"].custom-class.form--check-box'
        expect(output).to have_checked_field 'settings_field'
      end
    end

    context 'when setting is false' do
      before do
        expect(Setting).to receive(:field?).and_return(false)
      end

      it_behaves_like 'labelled by default'
      it_behaves_like 'wrapped in field-container by default'
      it_behaves_like 'wrapped in container', 'check-box-container'

      it 'should output element' do
        expect(output).to have_selector 'input[type="checkbox"].custom-class.form--check-box'
        expect(output).to have_unchecked_field 'settings_field'
      end
    end
  end

  describe '#setting_label' do
    subject(:output) {
      helper.setting_label :field
    }

    it_behaves_like 'labelled'
    it_behaves_like 'not wrapped in container'
  end

  describe '#notification_field' do
    before do
      expect(Setting).to receive(:notified_events).and_return(%w(interesting_stuff))
    end

    subject(:output) {
      helper.notification_field(notifiable, options)
    }

    context 'when setting includes option' do
      let(:notifiable) { OpenStruct.new(name: 'interesting_stuff') }

      it 'should have a label' do
        expect(output).to have_selector 'label.form--label-with-check-box', count: 1
      end

      it_behaves_like 'wrapped in container', 'check-box-container'

      it 'should output element' do
        expect(output).to have_selector 'input[type="checkbox"].form--check-box'
        expect(output).to have_checked_field 'Interesting stuff'
      end
    end

    context 'when setting does not include option' do
      let(:notifiable) { OpenStruct.new(name: 'boring_stuff') }

      it 'should have a label' do
        expect(output).to have_selector 'label.form--label-with-check-box', count: 1
      end

      it_behaves_like 'wrapped in container', 'check-box-container'

      it 'should output element' do
        expect(output).to have_selector 'input[type="checkbox"].form--check-box'
        expect(output).to have_unchecked_field 'Boring stuff'
      end
    end
  end
end
