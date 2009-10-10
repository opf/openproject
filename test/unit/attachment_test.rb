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

require File.dirname(__FILE__) + '/../test_helper'

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
    assert_equal Digest::MD5.hexdigest(uploaded_test_file("testfile.txt", "text/plain").read), a.digest
    assert File.exist?(a.diskfile)
  end
  
  def test_diskfilename
    assert Attachment.disk_filename("test_file.txt") =~ /^\d{12}_test_file.txt$/
    assert_equal 'test_file.txt', Attachment.disk_filename("test_file.txt")[13..-1]
    assert_equal '770c509475505f37c2b8fb6030434d6b.txt', Attachment.disk_filename("test_accentué.txt")[13..-1]
    assert_equal 'f8139524ebb8f32e51976982cd20a85d', Attachment.disk_filename("test_accentué")[13..-1]
    assert_equal 'cbb5b0f30978ba03731d61f9f6d10011', Attachment.disk_filename("test_accentué.ça")[13..-1]
  end
end
