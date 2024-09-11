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

RSpec.describe OpenProject::JournalFormatter::FileLink do
  let(:work_package) { build(:work_package) }
  let(:journal) { instance_double(Journal, journable: work_package) }
  let(:file_link) { create(:file_link, container: work_package, storage: build(:nextcloud_storage)) }
  let(:key) { "file_links_#{file_link.id}" }

  let(:changes) { { "link_name" => file_link.origin_name, "storage_name" => file_link.storage.name } }

  subject(:instance) { described_class.new(journal) }

  describe "#render" do
    context "having the origin_name as nil" do
      let(:changes) { { "link_name" => file_link.origin_name, "storage_name" => nil } }

      it "if the storage name is nil it tries to find it out looking at the file link" do
        link = "#{Setting.protocol}://#{Setting.host_name}/api/v3/file_links/#{file_link.id}/open"

        expect(instance.render(key, [nil, changes]))
          .to eq(I18n.t(:text_journal_file_link_added,
                        label: "<strong>#{I18n.t('activerecord.models.file_link')}</strong>",
                        value: "<a href=\"#{link}\">#{file_link.origin_name}</a>",
                        storage: file_link.storage.name))
      end

      it 'if the storage name is nil and the file link does not exist, "Unknown storage" is used' do
        expect(instance.render("file_links_12", [changes, nil]))
          .to eq(I18n.t(:text_journal_file_link_deleted,
                        label: "<strong>#{I18n.t('activerecord.models.file_link')}</strong>",
                        old: "<strike><i>#{file_link.origin_name}</i></strike>",
                        storage: I18n.t(
                          "unknown_storage",
                          scope: "my_account.access_tokens.storages"
                        )))
      end
    end

    context "having the first value being nil, and the second an hash of properties" do
      context "as HTML" do
        it "adds a file link added text" do
          link = "#{Setting.protocol}://#{Setting.host_name}/api/v3/file_links/#{file_link.id}/open"
          expect(instance.render(key, [nil, changes]))
            .to eq(I18n.t(:text_journal_file_link_added,
                          label: "<strong>#{I18n.t('activerecord.models.file_link')}</strong>",
                          value: "<a href=\"#{link}\">#{file_link.origin_name}</a>",
                          storage: file_link.storage.name))
        end

        context "with a configured relative url root" do
          before { allow(OpenProject::Configuration).to receive(:rails_relative_url_root).and_return("/blubs") }

          it "adds an file link added text" do
            link = "#{Setting.protocol}://#{Setting.host_name}/blubs/api/v3/file_links/#{file_link.id}/open"
            expect(instance.render(key, [nil, changes]))
              .to eq(I18n.t(:text_journal_file_link_added,
                            label: "<strong>#{I18n.t('activerecord.models.file_link')}</strong>",
                            value: "<a href=\"#{link}\">#{file_link.origin_name}</a>",
                            storage: file_link.storage.name))
          end
        end
      end

      context "as plain text" do
        it "adds a file link added text" do
          message = I18n.t(:text_journal_file_link_added,
                           label: I18n.t("activerecord.models.file_link"),
                           value: file_link.origin_name,
                           storage: file_link.storage.name)

          expect(instance.render(key, [nil, changes], html: false)).to eq(message)
        end
      end
    end

    context "having the first value being an props hash, and the second nil" do
      context "as HTML" do
        it "adds a file link remove text" do
          message = I18n.t(:text_journal_file_link_deleted,
                           label: "<strong>#{I18n.t('activerecord.models.file_link')}</strong>",
                           old: "<strike><i>#{file_link.origin_name}</i></strike>",
                           storage: file_link.storage.name)

          expect(instance.render(key, [changes, nil])).to eq(message)
        end
      end

      context "as plain text" do
        it "adds a file link removed" do
          message = I18n.t(:text_journal_file_link_deleted,
                           label: I18n.t("activerecord.models.file_link"),
                           old: file_link.origin_name,
                           storage: file_link.storage.name)

          expect(instance.render(key, [changes, nil], html: false)).to eq(message)
        end
      end
    end
  end
end
