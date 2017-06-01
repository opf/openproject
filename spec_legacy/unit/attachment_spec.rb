#-- encoding: UTF-8
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
require 'legacy_spec_helper'

describe Attachment, type: :model do
  fixtures :all

  it 'should create' do
    a = Attachment.new(container: WorkPackage.find(1),
                       file: uploaded_test_file('testfile.txt', 'text/plain'),
                       author: User.find(1))
    assert a.save
    assert_equal 'testfile.txt', a.filename
    assert_equal 57, a.filesize
    assert_equal 'text/plain', a.content_type
    assert_equal 0, a.downloads
    assert_equal 'f94d862ca1e4363e760431025673826c', a.digest
    assert File.exist?(a.diskfile)
  end

  it 'should create should auto assign content type' do
    a = Attachment.new(container: WorkPackage.find(1),
                       file: uploaded_test_file('testfile.txt', ''),
                       author: User.find(1))
    assert a.save
    assert_equal 'text/plain', a.content_type
  end

  it 'should identical attachments at the same time should not overwrite' do
    a1 = Attachment.create!(container: WorkPackage.find(1),
                            file: uploaded_test_file('testfile.txt', ''),
                            author: User.find(1))
    a2 = Attachment.create!(container: WorkPackage.find(1),
                            file: uploaded_test_file('testfile.txt', ''),
                            author: User.find(1))
    assert a1.diskfile.path != a2.diskfile.path
  end

  context 'Attachmnet#attach_files' do
    it 'should add unsaved files to the object as unsaved attachments' do
      # Can't use with_settings: here due to before hook
      expect(Setting).to receive(:attachment_max_size)
        .exactly(4).times
        .and_return(0)

      @issue = WorkPackage.find(1)
      response = Attachment.attach_files(
        @issue,
        '1' => { 'file' => LegacyFileHelpers.mock_uploaded_file, 'description' => 'test 1' },
        '2' => { 'file' => LegacyFileHelpers.mock_uploaded_file, 'description' => 'test 2' })

      assert response[:unsaved].present?
      assert_equal 2, response[:unsaved].length
      assert response[:unsaved].first.new_record?
      assert response[:unsaved].second.new_record?
      assert_equal response[:unsaved], @issue.unsaved_attachments
    end
  end
end
