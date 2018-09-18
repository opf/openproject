#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

require 'spec_helper'

describe ::API::V3::Attachments::AttachmentRepresenter do
  include API::V3::Utilities::PathHelper

  let(:current_user) do
    FactoryBot.build_stubbed(:user)
  end
  let(:all_permissions) { %i[view_work_packages edit_work_packages] }
  let(:permissions) { all_permissions }

  let(:container) { FactoryBot.build_stubbed(:stubbed_work_package) }
  let(:author) { current_user }
  let(:attachment) do
    FactoryBot.build_stubbed(:attachment,
                             container: container,
                             author: author) do |attachment|
      allow(attachment)
        .to receive(:filename)
        .and_return('some_file_of_mine.txt')
    end
  end

  let(:representer) do
    ::API::V3::Attachments::AttachmentRepresenter.new(attachment, current_user: current_user)
  end

  before do
    allow(current_user)
      .to receive(:allowed_to?) do |permission|
      permissions.include? permission
    end
  end

  subject { representer.to_json }

  it { is_expected.to be_json_eql('Attachment'.to_json).at_path('_type') }
  it { is_expected.to be_json_eql(attachment.id.to_json).at_path('id') }
  it { is_expected.to be_json_eql(attachment.filename.to_json).at_path('fileName') }
  it { is_expected.to be_json_eql(attachment.filesize.to_json).at_path('fileSize') }
  it { is_expected.to be_json_eql(attachment.content_type.to_json).at_path('contentType') }

  it_behaves_like 'API V3 formattable', 'description' do
    let(:format) { 'plain' }
    let(:raw) { attachment.description }
  end

  it_behaves_like 'API V3 digest' do
    let(:path) { 'digest' }
    let(:algorithm) { 'md5' }
    let(:hash) { attachment.digest }
  end

  it_behaves_like 'has UTC ISO 8601 date and time' do
    let(:date) { attachment.created_at }
    let(:json_path) { 'createdAt' }
  end

  describe '_links' do
    it_behaves_like 'has a titled link' do
      let(:link) { 'self' }
      let(:href) { api_v3_paths.attachment(attachment.id) }
      let(:title) { attachment.filename }
    end

    context 'for a work package container' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'container' }
        let(:href) { api_v3_paths.work_package(container.id) }
        let(:title) { container.subject }
      end
    end

    context 'for a wiki page container' do
      let(:container) { FactoryBot.build_stubbed(:wiki_page) }

      it_behaves_like 'has a titled link' do
        let(:link) { 'container' }
        let(:href) { api_v3_paths.wiki_page(container.id) }
        let(:title) { container.title }
      end
    end

    context 'without a container' do
      let(:container) { nil }

      it_behaves_like 'has an untitled link' do
        let(:link) { 'container' }
        let(:href) { nil }
      end
    end

    describe 'downloadLocation link' do
      context 'for a local attachment' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'downloadLocation' }
          let(:href) { api_v3_paths.attachment_content(attachment.id) }
        end
      end

      context 'for a remote attachment' do
        let(:external_url) { 'https://some.bogus/download/xyz' }

        before do
          allow(attachment)
            .to receive(:external_storage?)
            .and_return(true)
          allow(attachment)
            .to receive(:external_url)
            .and_return(external_url)
        end

        it_behaves_like 'has an untitled link' do
          let(:link) { 'downloadLocation' }
          let(:href) { external_url }
        end

        it_behaves_like 'has an untitled link' do
          let(:link) { 'staticDownloadLocation' }
          let(:href) { api_v3_paths.attachment_content(attachment.id) }
        end
      end
    end

    it_behaves_like 'has a titled link' do
      let(:link) { 'author' }
      let(:href) { api_v3_paths.user(attachment.author.id) }
      let(:title) { attachment.author.name }
    end

    describe 'delete link' do
      it_behaves_like 'has an untitled link' do
        let(:link) { 'delete' }
        let(:href) { api_v3_paths.attachment(attachment.id) }
      end

      it 'has the DELETE method' do
        is_expected.to be_json_eql('delete'.to_json).at_path('_links/delete/method')
      end

      context 'user is not allowed to edit the container' do
        let(:permissions) { all_permissions - [:edit_work_packages] }

        it_behaves_like 'has no link' do
          let(:link) { 'delete' }
        end
      end

      context 'attachment has no container' do
        let(:container) { nil }

        context 'user is the author' do
          it_behaves_like 'has an untitled link' do
            let(:link) { 'delete' }
            let(:href) { api_v3_paths.attachment(attachment.id) }
          end
        end

        context 'user is not the author' do
          let(:author) { FactoryBot.build_stubbed(:user) }

          it_behaves_like 'has no link' do
            let(:link) { 'delete' }
          end
        end
      end
    end
  end

  describe 'caching' do
    it 'is based on the representer\'s cache_key' do
      expect(OpenProject::Cache)
        .to receive(:fetch)
        .with(representer.json_cache_key)
        .and_call_original

      representer.to_json
    end

    describe '#json_cache_key' do
      let!(:former_cache_key) { representer.json_cache_key }

      it 'includes the name of the representer class' do
        expect(representer.json_cache_key)
          .to include('API', 'V3', 'Attachments', 'AttachmentRepresenter')
      end

      it 'changes when the locale changes' do
        I18n.with_locale(:fr) do
          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end

      it 'changes when the attachment is changed (has no update)' do
        attachment.updated_at = Time.now + 10.seconds

        expect(representer.json_cache_key)
          .not_to eql former_cache_key
      end
    end
  end
end
