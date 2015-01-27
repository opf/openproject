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
#++
require File.expand_path('../../test_helper', __FILE__)

class AttachmentTest < ActiveSupport::TestCase
  fixtures :all

  def test_create
    a = Attachment.new(container: WorkPackage.find(1),
                       file: uploaded_test_file("testfile.txt", "text/plain"),
                       author: User.find(1))
    assert a.save
    assert_equal 'testfile.txt', a.filename
    assert_equal 59, a.filesize
    assert_equal 'text/plain', a.content_type
    assert_equal 0, a.downloads
    assert_equal '1478adae0d4eb06d35897518540e25d6', a.digest
    assert File.exist?(a.diskfile)
  end

  def test_create_should_auto_assign_content_type
    a = Attachment.new(container: WorkPackage.find(1),
                       file: uploaded_test_file("testfile.txt", ""),
                       author: User.find(1))
    assert a.save
    assert_equal 'text/plain', a.content_type
  end

  def test_identical_attachments_at_the_same_time_should_not_overwrite
    a1 = Attachment.create!(container: WorkPackage.find(1),
                            file: uploaded_test_file("testfile.txt", ""),
                            author: User.find(1))
    a2 = Attachment.create!(container: WorkPackage.find(1),
                            file: uploaded_test_file("testfile.txt", ""),
                            author: User.find(1))
    assert a1.diskfile.path != a2.diskfile.path
  end

  context "Attachmnet#attach_files" do
    should "add unsaved files to the object as unsaved attachments" do
      # Max size of 0 to force Attachment creation failures
      with_settings(attachment_max_size: 0) do
        @issue = WorkPackage.find(1)
        response = Attachment.attach_files(
          @issue,
          '1' => { 'file' => create_uploaded_file, 'description' => 'test 1' },
          '2' => { 'file' => create_uploaded_file, 'description' => 'test 2' })

        assert response[:unsaved].present?
        assert_equal 2, response[:unsaved].length
        assert response[:unsaved].first.new_record?
        assert response[:unsaved].second.new_record?
        assert_equal response[:unsaved], @issue.unsaved_attachments
      end
    end
  end
end
