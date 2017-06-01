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

When (/^I fill in a (\d+) hash(?:es)? quickinfo link to "([^"]*)" for "([^"]*)"$/) do |count, subject, container|
  count = count.to_i

  raise 'Only values between 1 and 3 are allowed for hashes' if count < 1 || count > 3

  work_package = WorkPackage.find_by(subject: subject)
  text = "#{('#' * count)}#{work_package.id}"

  step %{I fill in "#{text}" for "#{container}"}
end

When (/^I follow the (\d+) hash(?:es)? work package quickinfo link to "([^"]*)"$/) do |count, subject|
  count = count.to_i
  raise 'Only values between 1 and 3 are allowed for hashes' if count < 1 || count > 3

  work_package = WorkPackage.find_by(subject: subject)

  text = case count
         when 1
           "##{work_package.id}"
         when 2, 3
           "#{work_package.type} ##{work_package.id}".strip
         end

  step %{I follow "#{text}"}
end

Then /^I should (not )?see a (\d+) hash(?:es)? work package quickinfo link to "([^"]*)"$/ do |negate, count, subject|
  count = count.to_i
  raise 'Only values between 1 and 3 are allowed for hashes' if count < 1 || count > 3

  work_package = WorkPackage.find_by(subject: subject)

  expectation = negate ? :should_not : :should

  case count
  when 1
    send(expectation, have_css('a', text: "##{work_package.id}"))
  when 2
    send(expectation, have_css('a', text: "#{work_package.type} ##{work_package.id}".strip))
    send(expectation, have_text("#{work_package.subject} #{work_package.start_date} – #{work_package.due_date}"))
  when 3
    send(expectation, have_css('a', text: "#{work_package.type} ##{work_package.id}".strip))
    send(expectation, have_text("#{work_package.subject} #{work_package.start_date} – #{work_package.due_date}"))
    send(expectation, have_css('.quick_info.attributes', text: work_package.assigned_to.name)) if work_package.assigned_to
    send(expectation, have_css('.quick_info.attributes', text: work_package.responsible.name)) if work_package.responsible
    send(expectation, have_css('.quick_info.description', text: work_package.description)) if work_package.description
  end
end
