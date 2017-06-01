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

describe AttachmentsController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) {
    FactoryGirl.create(:role,
                       permissions: [:edit_work_packages,
                                     :view_work_packages,
                                     :delete_wiki_pages_attachments])
  }
  let!(:member) {
    FactoryGirl.create(:member,
                       project: project,
                       principal: user,
                       roles: [role])
  }

  before do allow(User).to receive(:current).and_return user end

  describe '#destroy' do
    let(:attachment) {
      FactoryGirl.create(:attachment,
                         container: container)
    }

    shared_examples_for :deleted do
      subject { Attachment.find_by(id: attachment.id) }

      it { is_expected.to be_nil }
    end

    shared_examples_for :redirected do
      subject { response }

      it { is_expected.to be_redirect }

      it { is_expected.to redirect_to(redirect_path) }
    end

    context 'work_package' do
      let(:container) {
        FactoryGirl.create(:work_package,
                           author: user,
                           project: project)
      }
      let(:redirect_path) { work_package_path(container) }

      before do
        delete :destroy, params: { id: attachment.id }
      end

      it_behaves_like :deleted

      it_behaves_like :redirected
    end

    context 'wiki' do
      let(:container) {
        FactoryGirl.create(:wiki_page,
                           wiki: project.wiki)
      }
      let(:redirect_path) { project_wiki_path(project, project.wiki) }

      before do
        project.reload # get wiki

        delete :destroy, params: { id: attachment.id }
      end

      it_behaves_like :deleted

      it_behaves_like :redirected
    end
  end

  describe '#download' do
    let(:file) { FileHelpers.mock_uploaded_file name: 'foobar.txt' }
    let(:work_package) { FactoryGirl.create :work_package, project: project }
    let(:uploader) { nil }

    ##
    # Stubs an attachment instance of the respective uploader.
    # It's an anonymous subclass of Attachment and can therefore
    # not be saved.
    let(:attachment) do
      clazz = Class.new Attachment
      clazz.mount_uploader :file, uploader

      ##
      # Override to_s for carrierwave to use the correct class name in the store dir.
      def clazz.to_s
        'attachment'
      end

      att = clazz.new container: work_package, author: user, file: file
      att.id = 42
      att.file.store!
      att.send :write_attribute, :file, file.original_filename
      att.send :write_attribute, :content_type, file.content_type
      att
    end

    before do
      allow(Attachment).to receive(:find).with(attachment.id.to_s).and_return(attachment)
    end

    subject {
      get :download, params: { id: attachment.id }
    }

    context 'with a local file' do
      let(:uploader) { LocalFileUploader }
      let(:url) { "http://test.host/attachments/#{attachment.id}/download/#{attachment.filename}" }
      let(:headers) { subject.headers }

      it 'serves the file' do
        expect(subject.status).to eq 200
        expect(headers['Content-Disposition']).to eq 'attachment; filename="foobar.txt"'
      end
    end

    context 'with a remote file' do
      let(:uploader) { FogFileUploader }
      let(:url) do
        host = 'https://test-bucket.s3.amazonaws.com'
        Regexp.new "#{host}/uploads/attachment/file/#{attachment.id}/#{attachment.filename}"
      end

      it 'redirects to AWS' do
        expect(subject.location).to match(url)
      end
    end
  end
end
