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

describe MessagesController, type: :controller do
  let(:user) { FactoryBot.create(:user) }
  let(:project) { FactoryBot.create(:project) }
  let(:role) { FactoryBot.create(:role) }
  let!(:member) do
    FactoryBot.create(:member,
                      project: project,
                      principal: user,
                      roles: [role])
  end
  let!(:board) do
    FactoryBot.create(:board,
                      project: project)
  end

  let(:filename) { 'testfile.txt' }
  let(:file) { File.open(Rails.root.join('spec/fixtures/files', filename)) }
  let(:uploaded_file) do
    fixture_file_upload "files/#{filename}", filename
  end

  before { allow(User).to receive(:current).and_return user }

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
    let(:message) { FactoryBot.create :message, board: board }
    let(:other_board) { FactoryBot.create :board, project: project }

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
    let!(:message) { FactoryBot.create(:message) }
    let(:attachment_id) { "attachments_#{message.attachments.first.id}" }
    let(:params) do
      { id: message.id,
        attachments: { '1' => { 'file' => uploaded_file,
                                'description' => '' } } }
    end

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
      let!(:attachment) do
        FactoryBot.create(:attachment,
                          container: message,
                          author: user,
                          filename: filename)
      end
      let!(:attachable_journal) do
        FactoryBot.create(:journal_attachable_journal,
                          journal: message.journals.last,
                          attachment: attachment,
                          filename: filename)
      end

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

  describe 'quote' do
    let(:message) { FactoryBot.create :message, content: 'foo', subject: 'subject', board: board }

    context 'when allowed' do
      let(:user) { FactoryBot.create(:admin) }

      before do
        login_as user
      end

      it 'renders the content as json' do
        get :quote, params: { board_id: board.id, id: message.id }, format: :json

        expect(response).to be_success
        expect(response.body).to eq '{"subject":"RE: subject","content":" wrote:\n\u003e foo\n\n"}'
      end
    end
  end
end
