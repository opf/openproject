
# Textile to Markdown converter
# Based on redmine_convert_textile_to_markown
# https://github.com/Ecodev/redmine_convert_textile_to_markown
#
# Original license:
# Copyright (c) 2016
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

namespace :markdown do
  task :convert_from_textile  => :environment do

    warning = <<~EOS
      **WARNING**
      THIS IS NOT REVERSIBLE.
      Ensure you have backed up your installation before running this task.

      This rake task will modify EVERY formattable textile field in your database.
      It uses pandoc to convert each textile field to GFM-Markdown.
    EOS

    printf "#{warning}\nPress 'y' to continue: "
    prompt = STDIN.gets.chomp
    exit(1) unless prompt == 'y'

    converter = OpenProject::TextFormatting::Formatters::Markdown::TextileConverter.new
    converter.run!
  end
end
