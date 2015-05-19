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

describe OpenProject::JournalFormatter::Attachment do

  include ApplicationHelper
  include ActionView::Helpers::TagHelper
  # WARNING: the order of the modules is important to ensure that url_for of
  # ActionController::UrlWriter is called and not the one of ActionView::Helpers::UrlHelper
  include ActionView::Helpers::UrlHelper
  include Rails.application.routes.url_helpers

  def self.default_url_options
    { only_path: true }
  end

  Struct.new('TestJournal', :id)

  let(:klass) { OpenProject::JournalFormatter::Attachment }
  let(:instance) { klass.new(journal) }
  let(:id) { 1 }
  let(:journal) do
    Struct::TestJournal.new(id)
  end
  let(:user) { FactoryGirl.create(:user) }
  let(:attachment) {
    FactoryGirl.create(:attachment,
                       author: user)
  }
  let(:key) { "attachments_#{attachment.id}" }

  describe '#render' do
    describe 'WITH the first value beeing nil, and the second an id as string' do
      # FIXME
      # calling a helper method (link_to_attachment in this case) doesn't work always here
      # with rspec-core 2.13.0 in combination with rspec-rails
      # see https://github.com/rspec/rspec-core/issues/817
      #
      # let(:expected) {
      #  I18n.t(:text_journal_added,
      #                        :label => "<strong>#{I18n.t(:label_attachment)}</strong>",
      #                        :value => link_to_attachment(attachment)) }

      # it { instance.render(key, [nil, attachment.id.to_s]).should == expected }
      #
      # Setting value by hand is just a workaround until rspec bug is fixed
      it { expect(instance.render(key, [nil, attachment.id.to_s])).to eq(I18n.t(:text_journal_added, label: "<strong>#{I18n.t(:'activerecord.models.attachment')}</strong>", value: "<a href=\"#{Setting.protocol}://#{Setting.host_name}/attachments/#{attachment.id}/#{attachment.filename}\">#{attachment.filename}</a>")) }
    end

    describe 'WITH the first value beeing an id as string, and the second nil' do
      let(:expected) {
        I18n.t(:text_journal_deleted,
               label: "<strong>#{I18n.t(:'activerecord.models.attachment')}</strong>",
               old: "<strike><i title=\"#{attachment.id}\">#{attachment.id}</i></strike>")
      }

      it { expect(instance.render(key, [attachment.id.to_s, nil])).to eq(expected) }
    end

    describe "WITH the first value beeing nil, and the second an id as a string
              WITH specifying not to output html" do
      let(:expected) {
        I18n.t(:text_journal_added,
               label: I18n.t(:'activerecord.models.attachment'),
               value: attachment.id)
      }

      it { expect(instance.render(key, [nil, attachment.id.to_s], no_html: true)).to eq(expected) }
    end

    describe "WITH the first value beeing an id as string, and the second nil,
              WITH specifying not to output html" do
      let(:expected) {
        I18n.t(:text_journal_deleted,
               label: I18n.t(:'activerecord.models.attachment'),
               old: attachment.id)
      }

      it { expect(instance.render(key, [attachment.id.to_s, nil], no_html: true)).to eq(expected) }
    end
  end
end
