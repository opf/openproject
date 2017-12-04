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
# TODO: Rewrite these tests to specs.
describe OpenProject::TextExtractor do
  #   fixtures :projects, :users, :attachments
  #
  #   setup do
  #     @project = Project.find_by_identifier 'ecookbook'
  #     set_fixtures_attachments_directory
  #     @dlopper = User.find_by_login 'dlopper'
  #   end
  #
  #   def attachment_for(filename, content_type = nil)
  #     Attachment.new(container: @project,
  #                    file: uploaded_test_file(filename, content_type),
  #                    filename: filename,
  #                    author: @dlopper).tap do |a|
  #       a.content_type = content_type if content_type
  #       a.save!
  #     end
  #   end
  #
  #   if Redmine::TextExtractor::PdfHandler.available?
  #     test "should extract text from pdf" do
  #       a = attachment_for "text.pdf"
  #       te = Redmine::TextExtractor.new a
  #       assert text = te.text
  #       assert_match /lorem ipsum fulltext find me!/, text
  #     end
  #   end
  #
  #   if Redmine::TextExtractor::RtfHandler.available?
  #     test "should extract text from rtf" do
  #       a = attachment_for "text.rtf"
  #       te = Redmine::TextExtractor.new a
  #       assert text = te.text
  #       assert_match /lorem ipsum fulltext find me!/, text
  #     end
  #   end
  #
  #   if Redmine::TextExtractor::DocHandler.available?
  #     test "should extract text from doc" do
  #       a = attachment_for "text.doc"
  #       te = Redmine::TextExtractor.new a
  #       assert text = te.text
  #       assert_match /lorem ipsum fulltext find me!/, text
  #     end
  #   end
  #
  #   if Redmine::TextExtractor::XlsHandler.available?
  #     test "should extract text from xls" do
  #       a = attachment_for "spreadsheet.xls"
  #       te = Redmine::TextExtractor.new a
  #       assert text = te.text
  #       assert_match /lorem ipsum fulltext find me!/, text
  #     end
  #   end
  #
  #
  #   %w(txt docx odt ott).each do |type|
  #     test "should extract text from #{type}" do
  #       a = attachment_for "text.#{type}"
  #       te = Redmine::TextExtractor.new a
  #       assert text = te.text
  #       assert_match /lorem ipsum fulltext find me!/, text
  #     end
  #   end
  #
  #
  #   %w(xlsx ods ots).each do |type|
  #     test "should extract text from #{type}" do
  #       a = attachment_for "spreadsheet.#{type}"
  #       te = Redmine::TextExtractor.new a
  #       assert text = te.text
  #       assert_match /lorem ipsum fulltext find me!/, text
  #     end
  #   end
  #
  #
  #   %w(pptx ppsx potm odp otp).each do |type|
  #     test "should extract text from #{type}" do
  #       a = attachment_for "presentation.#{type}"
  #       te = Redmine::TextExtractor.new a
  #       assert text = te.text
  #       assert_equal 'The Title find me Slide two Click To Add Text', text
  #     end
  #   end
  #
  #
  #   test "should extract text from csv" do
  #     a = attachment_for "spreadsheet.csv"
  #     te = Redmine::TextExtractor.new a
  #     assert text = te.text
  #     assert_match /lorem ipsum fulltext find me!/, text.gsub(/(,+|\n+\s*)/m, ' ').squeeze(' ')
  #   end
  #
  # end
  #
end
