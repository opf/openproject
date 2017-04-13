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

describe 'Angular expression escaping', type: :feature do
  include OpenProject::TextFormatting

  describe 'login field' do
    let(:login_field) { find('#username') }

    before do
      visit signin_path
      within('#login-form') do
        fill_in('username', with: login_string)
        click_link_or_button I18n.t(:button_login)
      end

      expect(current_path).to eq signin_path
    end

    describe 'Simple expression' do
      let(:login_string) { '{{ 3 + 5 }}' }

      it 'does not evaluate the expression' do
        expect(login_field.value).to eq('{{ $root.DOUBLE_LEFT_CURLY_BRACE }} 3 + 5 }}')
      end
    end

    context 'With JavaScript evaluation', js: true do
      describe 'Simple expression' do
        let(:login_string) { '{{ 3 + 5 }}' }

        it 'does not evaluate the expression' do
          expect(login_field.value).to eq(login_string)
        end
      end

      describe 'Angular 1.3 Sandbox evading' do
        let(:login_string) { "{{'a'.constructor.prototype.charAt=[].join;$eval('x=alert(1)'); }" }

        it 'does not evaluate the expression' do
          expect(login_field.value).to eq(login_string)
          expect { page.driver.browser.switch_to.alert }
            .to raise_error(::Selenium::WebDriver::Error::NoAlertPresentError)
        end
      end
    end
  end

  describe '#WorkPackage description field', js: true do
    let(:project) { FactoryGirl.create :project }
    let(:property_name) { :description }
    let(:property_title) { 'Description' }
    let(:description_text) { 'Expression {{ 3 + 5 }}' }
    let!(:work_package) {
      FactoryGirl.create(
        :work_package,
        project: project,
        description: description_text
      )
    }
    let(:user) { FactoryGirl.create :admin }
    let(:field) { WorkPackageTextAreaField.new wp_page, 'description' }
    let(:wp_page) { Pages::SplitWorkPackage.new(work_package, project) }

    before do
      login_as(user)

      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it 'properly renders the unescaped string' do
      field.expect_state_text description_text
      field.activate!

      new_description = 'My new expression {{ 5 + 1 }}'
      field.set_value new_description
      field.submit_by_click

      wp_page.expect_notification message: I18n.t('js.notice_successful_update')
      field.expect_state_text new_description
    end
  end

  describe '#wiki edit previewing', js: true do
    let(:user) { FactoryGirl.create :admin }
    let(:project) { FactoryGirl.create :project, enabled_module_names: %w(wiki) }

    let(:content) { find '#content_text' }
    let(:preview) { find '#preview' }
    let(:btn_preview) { find '#wiki_form-preview' }
    let(:btn_cancel) { find '#wiki_form a.button', text: I18n.t(:button_cancel) }

    before do
      login_as(user)
      visit project_wiki_path(project, project.wiki)
    end

    it 'properly escapes a macro in the preview functionality' do
      content.set '{{macro_list(wiki)}}'
      btn_preview.click

      expect(preview.text).not_to include '{{ $root.DOUBLE_LEFT_CURLY_BRACE }}'
      expect(preview.text).to match /\{\{[\s\w]+\}\}/

      btn_cancel.click
    end
  end

  describe '#text_format' do
    let(:text) { '{{hello_world}} {{ 3 + 5 }}' }
    subject(:html) { format_text(text) }

    it 'expands the macro' do
      expect(html).to start_with('<p>Hello world!')
    end

    it 'escapes the expression' do
      expect(html).to include('{{ $root.DOUBLE_LEFT_CURLY_BRACE }} 3 + 5 }}')
    end

    it 'marks the string as safe' do
      expect(html).to be_html_safe
    end
  end
end
