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

describe MessagesController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role) }
  let!(:member) {
    FactoryGirl.create(:member,
                       project: project,
                       principal: user,
                       roles: [role])
  }
  let!(:board) {
    FactoryGirl.create(:board,
                       project: project)
  }

  let(:filename) { 'testfile.txt' }
  let(:file) { File.open(Rails.root.join('spec/fixtures/files', filename)) }
  let(:uploaded_file) do
    fixture_file_upload "files/#{filename}", filename
  end

  before do allow(User).to receive(:current).and_return user end

  describe '#create' do
    context 'attachments' do
      # see ticket #2464 on OpenProject.org
      context 'new attachment on new messages' do
        before do
          expect(controller).to receive(:authorize).and_return(true)

          allow_any_instance_of(Attachment).to receive(:filename).and_return(filename)

          post 'create', params: { board_id: board.id,
                                   message: { subject: 'Test created message',
                                              content: 'Messsage body' },
                                   attachments: { '1' => { 'file' => uploaded_file,
                                                           'description' => '' } } }
        end

        describe '#journal' do
          let(:attachment_id) { "attachments_#{Message.last.attachments.first.id}" }

          subject { Message.last.journals.last.details }

          it { is_expected.to have_key attachment_id }

          it { expect(subject[attachment_id]).to eq([nil, filename]) }
        end
      end
    end
  end

  describe '#update' do
    let(:message) { FactoryGirl.create :message, board: board }
    let(:other_board) { FactoryGirl.create :board, project: project }

    before do
      role.add_permission!(:edit_messages) and user.reload
      put :update, params: { id: message,
                             message: { board_id: other_board } }
    end

    it 'allows for changing the board' do
      expect(message.reload.board).to eq(other_board)
    end
  end

  describe '#attachment' do
    let!(:message) { FactoryGirl.create(:message) }
    let(:attachment_id) { "attachments_#{message.attachments.first.id}" }
    let(:params) {
      { id: message.id,
        attachments: { '1' => { 'file' => uploaded_file,
                                'description' => '' } } }
    }

    describe '#add' do
      before do
        allow_any_instance_of(Message).to receive(:editable_by?).and_return(true)

        allow_any_instance_of(Attachment).to receive(:filename).and_return(filename)
      end

      context 'invalid attachment' do
        let(:max_filesize) { Setting.attachment_max_size.to_i.kilobytes }

        before do
          allow_any_instance_of(Attachment).to receive(:filesize).and_return(max_filesize + 1)

          put :update, params: params
        end

        describe '#view' do
          subject { response }

          it { is_expected.to render_template('messages/edit') }
        end

        describe '#error' do
          subject { assigns(:message).errors.messages }

          it { is_expected.to have_key(:attachments) }

          it { subject[:attachments] =~ /too long/ }
        end
      end

      context 'journal' do
        before do
          put :update, params: params

          message.reload
        end

        describe '#key' do
          subject { message.journals.last.details }

          it { is_expected.to have_key attachment_id }
        end

        describe '#value' do
          subject { message.journals.last.details[attachment_id].last }

          it { is_expected.to eq(filename) }
        end
      end
    end

    describe '#remove' do
      let!(:attachment) {
        FactoryGirl.create(:attachment,
                           container: message,
                           author: user,
                           filename: filename)
      }
      let!(:attachable_journal) {
        FactoryGirl.create(:journal_attachable_journal,
                           journal: message.journals.last,
                           attachment: attachment,
                           filename: filename)
      }

      before do
        message.reload
        message.attachments.delete(attachment)
        message.reload
      end

      context 'journal' do
        let(:attachment_id) { "attachments_#{attachment.id}" }

        describe '#key' do
          subject { message.journals.last.details }

          it { is_expected.to have_key attachment_id }
        end

        describe '#value' do
          subject { message.journals.last.details[attachment_id].first }

          it { is_expected.to eq(filename) }
        end
      end
    end
  end

  describe 'preview' do
    let(:content) { 'Message content' }

    it_behaves_like 'valid preview' do
      let(:preview_texts) { [content] }
      let(:preview_params) { { message: { content: content } } }
    end

    it_behaves_like 'valid preview' do
      let(:preview_texts) { [content] }
      let(:preview_params) { { reply: { content: content } } }
    end

    it_behaves_like 'authorizes object access' do
      let(:message) { FactoryGirl.create :message, board: board }
      let(:preview_params) { { id: message.id, message: {} } }
    end
  end
end
