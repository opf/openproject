# encoding: utf-8
#
# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

require File.expand_path('../../test_helper', __FILE__)

class AttachmentTest < ActiveSupport::TestCase
  fixtures :issues, :users
  
  def setup
  end

  def test_create
    a = Attachment.new(:container => Issue.find(1),
                       :file => uploaded_test_file("testfile.txt", "text/plain"),
                       :author => User.find(1))
    assert a.save
    assert_equal 'testfile.txt', a.filename
    assert_equal 59, a.filesize
    assert_equal 'text/plain', a.content_type
    assert_equal 0, a.downloads
    assert_equal '1478adae0d4eb06d35897518540e25d6', a.digest
    assert File.exist?(a.diskfile)
  end
  
  def test_create_should_auto_assign_content_type
    a = Attachment.new(:container => Issue.find(1),
                       :file => uploaded_test_file("testfile.txt", ""),
                       :author => User.find(1))
    assert a.save
    assert_equal 'text/plain', a.content_type
  end
  
  def test_identical_attachments_at_the_same_time_should_not_overwrite
    a1 = Attachment.create!(:container => Issue.find(1),
                            :file => uploaded_test_file("testfile.txt", ""),
                            :author => User.find(1))
    a2 = Attachment.create!(:container => Issue.find(1),
                            :file => uploaded_test_file("testfile.txt", ""),
                            :author => User.find(1))
    assert a1.disk_filename != a2.disk_filename
  end
  
  def test_diskfilename
    assert Attachment.disk_filename("test_file.txt") =~ /^\d{12}_test_file.txt$/
    assert_equal 'test_file.txt', Attachment.disk_filename("test_file.txt")[13..-1]
    assert_equal '770c509475505f37c2b8fb6030434d6b.txt', Attachment.disk_filename("test_accentué.txt")[13..-1]
    assert_equal 'f8139524ebb8f32e51976982cd20a85d', Attachment.disk_filename("test_accentué")[13..-1]
    assert_equal 'cbb5b0f30978ba03731d61f9f6d10011', Attachment.disk_filename("test_accentué.ça")[13..-1]
  end

  context "Attachmnet#attach_files" do
    should "add unsaved files to the object as unsaved attachments" do
      # Max size of 0 to force Attachment creation failures
      with_settings(:attachment_max_size => 0) do
        @project = Project.generate!
        response = Attachment.attach_files(@project, {
                                             '1' => {'file' => mock_file, 'description' => 'test'},
                                             '2' => {'file' => mock_file, 'description' => 'test'}
                                           })

        assert response[:unsaved].present?
        assert_equal 2, response[:unsaved].length
        assert response[:unsaved].first.new_record?
        assert response[:unsaved].second.new_record?
        assert_equal response[:unsaved], @project.unsaved_attachments
      end
    end
  end
end
