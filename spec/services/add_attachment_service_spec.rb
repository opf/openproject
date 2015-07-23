#-- encoding: UTF-8
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

require 'spec_helper'

describe AddAttachmentService do
  let(:user) { FactoryGirl.build(:user) }
  let(:work_package) { FactoryGirl.build(:work_package) }
  let(:container) { work_package}
  let(:description) { 'a fancy description' }

  subject { described_class.new(work_package, author: user) }

  describe '#add_attachment' do
    before do
      subject.add_attachment uploaded_file: FileHelpers.mock_uploaded_file(name: 'foobar.txt'),
                             description: description
    end

    it 'should save the attachment' do
      attachment = Attachment.first
      expect(attachment.filename).to eq 'foobar.txt'
      expect(attachment.description).to eq description
    end

    it 'should add the attachment to the WP' do
      work_package.reload
      expect(work_package.attachments).to include Attachment.first
    end

    it 'should add a journal entry on the WP' do
      expect(work_package.journals.count).to eq 2 # 1 for WP creation + 1 for the attachment
    end
  end
end
