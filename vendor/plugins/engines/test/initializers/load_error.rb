#-- encoding: UTF-8
# Fixes Rails 2.3 and Ruby 1.9.x incompatibility
# See https://groups.google.com/d/topic/rubyonrails-core/gb5woRkmDlk/discussion
MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]