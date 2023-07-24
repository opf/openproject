# frozen_string_literal: true

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

RSpec.describe OpenProject::JournalFormatter::FileLink do
  let(:work_package) { create(:work_package) }
  let(:journal) { instance_double(Journal, journable: work_package) }
  let(:file_link) { create(:file_link, container: work_package) }
  let(:key) { "file_links_#{file_link.id}" }

  subject(:instance) { described_class.new(journal) }

  describe '#render' do
    context 'having the first value being nil, and the second an file link name as string' do
      context 'as HTML' do
        it 'adds a file link added text' do
          link = "#{Setting.protocol}://#{Setting.host_name}/api/v3/file_links/#{file_link.id}/open"
          expect(instance.render(key, [nil, file_link.origin_name]))
            .to eq(I18n.t(:text_journal_added,
                          label: "<strong>#{I18n.t(:'activerecord.models.file_link')}</strong>",
                          value: "<a href=\"#{link}\">#{file_link.origin_name}</a>"))
        end

        context 'with a configured relative url root' do
          before { allow(OpenProject::Configuration).to receive(:rails_relative_url_root).and_return('/blubs') }

          it 'adds an file link added text' do
            link = "#{Setting.protocol}://#{Setting.host_name}/blubs/api/v3/file_links/#{file_link.id}/open"
            expect(instance.render(key, [nil, file_link.origin_name]))
              .to eq(I18n.t(:text_journal_added,
                            label: "<strong>#{I18n.t(:'activerecord.models.file_link')}</strong>",
                            value: "<a href=\"#{link}\">#{file_link.origin_name}</a>"))
          end
        end
      end

      context 'as plain text' do
        it 'adds a file link added text' do
          message = I18n.t(:text_journal_added,
                           label: I18n.t(:'activerecord.models.file_link'),
                           value: file_link.id)

          expect(instance.render(key, [nil, file_link.id.to_s], html: false)).to eq(message)
        end
      end
    end

    context 'having the first value being an id as string, and the second nil' do
      context 'as HTML' do
        it 'adds a file link remove text' do
          message = I18n.t(:text_journal_deleted,
                           label: "<strong>#{I18n.t(:'activerecord.models.file_link')}</strong>",
                           old: "<strike><i>#{file_link.id}</i></strike>")

          expect(instance.render(key, [file_link.id.to_s, nil])).to eq(message)
        end
      end

      context 'as plain text' do
        it 'adds a file link removed' do
          message = I18n.t(:text_journal_deleted, label: Storages::FileLink.model_name.human, old: file_link.id)

          expect(instance.render(key, [file_link.id.to_s, nil], html: false)).to eq(message)
        end
      end
    end
  end
end
