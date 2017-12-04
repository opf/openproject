# TODO: finish this spec

# require 'test_helper'
#
# class ExtractFulltextJobTest < ActiveJob::TestCase
#   def test_should_extract_fulltext
#     attachment = nil
#     OpenProject::Configuration.with 'enable_attachment_search' => false do
#     attachment = Attachment.create(
#       :container => Issue.find(1),
#                 :file => uploaded_test_file("testfile.txt", "text/plain"),
#                 :author => User.find(1),
#                 :content_type => 'text/plain')
#     end
#     attachment.reload
#     assert_nil attachment.fulltext
#     ExtractFulltextJob.perform_now(attachment.id)
#
#     attachment.reload
#     assert attachment.fulltext.include?("this is a text file for upload tests with multiple lines")
#   end
# end
