#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe OpenProject::JournalFormatter::Diff do

  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper
  include ActionView::Helpers::UrlHelper

  def url_helper
    Rails.application.routes.url_helpers
  end

  Struct.new('TestJournal', :id, :journable)

  let(:klass) { OpenProject::JournalFormatter::Diff }
  let(:id) { 1 }
  let(:journal) do
    Struct::TestJournal.new(id, WorkPackage.new)
  end
  let(:instance) { klass.new(journal) }
  let(:key) { 'description' }

  let(:url) {
    url_helper.journal_diff_path(id: journal.id,
                                 field: key.downcase)
  }
  let(:full_url) {
    url_helper.journal_diff_url(id: journal.id,
                                field: key.downcase,
                                protocol: Setting.protocol,
                                host: Setting.host_name)
  }
  let(:link) { link_to(I18n.t(:label_details), url, class: 'description-details') }
  let(:full_url_link) { link_to(I18n.t(:label_details), full_url, class: 'description-details') }

  describe '#render' do
    describe 'WITH the first value beeing nil, and the second a string' do
      let(:expected) {
        I18n.t(:text_journal_set_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link: link)
      }

      it { expect(instance.render(key, [nil, 'new value'])).to eq(expected) }
    end

    describe 'WITH the first value beeing a string, and the second a string' do
      let(:expected) {
        I18n.t(:text_journal_changed_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link: link)
      }

      it { expect(instance.render(key, ['old value', 'new value'])).to eq(expected) }
    end

    describe "WITH the first value beeing a string, and the second a string
              WITH de as locale" do

      let(:expected) {
        I18n.t(:text_journal_changed_with_diff,
               label: '<strong>Beschreibung</strong>',
               link: link)
      }

      before do
        I18n.locale = :de
      end

      it { expect(instance.render(key, ['old value', 'new value'])).to eq(expected) }

      after do
        I18n.locale = :en
      end
    end

    describe 'WITH the first value beeing a string, and the second nil' do
      let(:expected) {
        I18n.t(:text_journal_deleted_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link: link)
      }

      it { expect(instance.render(key, ['old_value', nil])).to eq(expected) }
    end

    describe "WITH the first value beeing nil, and the second a string
              WITH specifying not to output html" do
      let(:expected) {
        I18n.t(:text_journal_set_with_diff,
               label: key.camelize,
               link: url)
      }

      it { expect(instance.render(key, [nil, 'new value'], no_html: true)).to eq(expected) }
    end

    describe "WITH the first value beeing a string, and the second a string
              WITH specifying not to output html" do
      let(:expected) {
        I18n.t(:text_journal_changed_with_diff,
               label: key.camelize,
               link: url)
      }

      it { expect(instance.render(key, ['old value', 'new value'], no_html: true)).to eq(expected) }
    end

    describe "WITH the first value beeing a string, and the second a string
              WITH specifying to output a full url" do
      let(:expected) {
        I18n.t(:text_journal_changed_with_diff,
               label: "<strong>#{key.camelize}</strong>",
               link: full_url_link)
      }

      it { expect(instance.render(key, ['old value', 'new value'], only_path: false)).to eq(expected) }
    end

    describe 'WITH the first value beeing a string, and the second nil' do
      let(:expected) {
        I18n.t(:text_journal_deleted_with_diff,
               label: key.camelize,
               link: url)
      }

      it { expect(instance.render(key, ['old_value', nil], no_html: true)).to eq(expected) }
    end
  end
end
