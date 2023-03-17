#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe OpenProject::JournalFormatter::Diff do
  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper
  include ActionView::Helpers::UrlHelper

  def url_helper
    Rails.application.routes.url_helpers
  end

  let(:klass) { OpenProject::JournalFormatter::Diff }
  # let(:id) { 1 }
  # let(:journal) do
  #   OpenStruct.new(id:, journable: WorkPackage.new)
  # end
  # let(:instance) { klass.new(journal) }
  # let(:key) { 'description' }

  # let(:url) do
  #   url_helper.diff_journal_path(id: journal.id,
  #                                field: key.downcase)
  # end
  # let(:full_url) do
  #   url_helper.diff_journal_url(id: journal.id,
  #                               field: key.downcase,
  #                               protocol: Setting.protocol,
  #                               host: Setting.host_name)
  # end
  # let(:link) { link_to(I18n.t(:label_details), url, class: 'description-details') }
  # let(:full_url_link) { link_to(I18n.t(:label_details), full_url, class: 'description-details') }

  # test where the link redirects

  # describe '#render' do
  #   describe 'WITH the first value being nil, and the second a string' do
  #     let(:expected) do
  #       I18n.t(:text_journal_set_with_diff,
  #              label: "<strong>#{key.camelize}</strong>",
  #              link:)
  #     end

  #     it { expect(instance.render(key, [nil, 'new value'])).to eq(expected) }
  #   end

  #   describe 'WITH the first value being a string, and the second a string' do
  #     let(:expected) do
  #       I18n.t(:text_journal_changed_with_diff,
  #              label: "<strong>#{key.camelize}</strong>",
  #              link:)
  #     end

  #     it { expect(instance.render(key, ['old value', 'new value'])).to eq(expected) }
  #   end

  #   describe "WITH the first value being a string, and the second a string
  #             WITH de as locale" do
  #     let(:expected) do
  #       I18n.t(:text_journal_changed_with_diff,
  #              label: '<strong>Beschreibung</strong>',
  #              link:)
  #     end

  #     before do
  #       I18n.locale = :de
  #     end

  #     after do
  #       I18n.locale = :en
  #     end

  #     it { expect(instance.render(key, ['old value', 'new value'])).to eq(expected) }
  #   end

  #   describe 'WITH the first value being a string, and the second nil' do
  #     let(:expected) do
  #       I18n.t(:text_journal_deleted_with_diff,
  #              label: "<strong>#{key.camelize}</strong>",
  #              link:)
  #     end

  #     it { expect(instance.render(key, ['old_value', nil])).to eq(expected) }
  #   end

  #   describe "WITH the first value being nil, and the second a string
  #             WITH specifying not to output html" do
  #     let(:expected) do
  #       I18n.t(:text_journal_set_with_diff,
  #              label: key.camelize,
  #              link: url)
  #     end

  #     it { expect(instance.render(key, [nil, 'new value'], html: false)).to eq(expected) }
  #   end

  #   describe "WITH the first value being a string, and the second a string
  #             WITH specifying not to output html" do
  #     let(:expected) do
  #       I18n.t(:text_journal_changed_with_diff,
  #              label: key.camelize,
  #              link: url)
  #     end

  #     it { expect(instance.render(key, ['old value', 'new value'], html: false)).to eq(expected) }
  #   end

  #   describe "WITH the first value being a string, and the second a string
  #             WITH specifying to output a full url" do
  #     let(:expected) do
  #       I18n.t(:text_journal_changed_with_diff,
  #              label: "<strong>#{key.camelize}</strong>",
  #              link: full_url_link)
  #     end

  #     it { expect(instance.render(key, ['old value', 'new value'], only_path: false)).to eq(expected) }
  #   end

  #   describe 'WITH the first value being a string, and the second nil' do
  #     let(:expected) do
  #       I18n.t(:text_journal_deleted_with_diff,
  #              label: key.camelize,
  #              link: url)
  #     end

  #     it { expect(instance.render(key, ['old_value', nil], html: false)).to eq(expected) }
  #   end
  # end


    # shared_let(:wiki) { create(:wiki) }
    #   shared_let(:wiki_page) { create(:wiki_page, wiki:) }
    #   shared_let(:wiki_content) do
    #     create(:wiki_content, page_id: wiki_page.id, author_id: user.id, text: '')
    #   end
    #   let(:params) { { id: wiki_content.id.to_s, field: :text, format: 'js' } }

  let(:wikiid) { 2 }
  let(:project) { create(:project) }
  let(:wiki) { create(:wiki, project:) }
  let(:wiki_page) { create(:wiki_page, wiki:) }
  let(:wiki_content) do
        create(:wiki_content, page_id: wiki_page.id, text: '')
      end
  let(:wikijournal) do
    OpenStruct.new(journable: wiki_content, version: 1, id: wiki_page.slug)
  end
  let(:wikiinstance) { klass.new(wikijournal) }
  let(:wikikey) { 'text' }

  let(:url) do
    url_helper.wiki_diff_compare_project_wiki_path(id: wikijournal.id,
                                 project_id: project.identifier,
                                 version: 0,
                                 version_from: 1)
  end
  let(:full_url) do
    url_helper.wiki_diff_compare_project_wiki_url(id: wikijournal.id,
                                project_id: project.identifier,
                                version: 0,
                                version_from: 1,
                                protocol: Setting.protocol,
                                host: Setting.host_name)
  end
  let(:link) { link_to(I18n.t(:label_details), url, class: 'description-details') }
  let(:full_url_link) { link_to(I18n.t(:label_details), full_url, class: 'description-details') }

  describe 'render for wiki' do
    describe 'WITH the first value being a string, and the second a string' do
      let(:expected) do
        I18n.t(:text_journal_changed_with_diff,
               label: "<strong>#{wikikey.camelize}</strong>",
               link:)
      end

      it { expect(wikiinstance.render(wikikey, ['old value', 'new value'])).to eq(expected) }
    end
  end

end
