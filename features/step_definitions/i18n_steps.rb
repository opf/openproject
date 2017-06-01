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

Given /^the following languages are active:$/ do |table|
  Setting.available_languages = table.raw.flatten
end

Given /^the (.+) called "(.+)" has the following localizations:$/ do |model_name, object_name, table|
  model = model_name.downcase.gsub(/\s/, '_').camelize.constantize
  object = model.find_by(name: object_name)

  object.translations = []

  table.hashes.each do |h|
    h.each do |k, v|
      h[k] = nil if v == 'nil'
    end

    object.translations.create h
  end
end

When /^I delete the (.+) localization of the "(.+)" attribute$/ do |language, attribute|
  locale = locale_for_language language

  page.should have_selector("span.#{attribute}_translation :first-child")
  spans = page.all(:css, "span.#{attribute}_translation")
  # Use the [] method since Firefox doesn't change the 'selected' attribute
  # when choosing the last available option of a select where all other
  # options are disabled. Check scenario 'Deleting a newly added localization'
  # when changing this.
  span = spans.detect { |span|
    span.find(:css, '.locale_selector')['value'] == locale
  }

  destroy = span.find(:css, 'a.destroy_locale')

  destroy.click
end

When /^I change the (.+) localization of the "(.+)" attribute to be (.+)$/ do |language, attribute, new_language|
  attribute_span = span_for_localization language, attribute

  locale_selector = attribute_span.find(:css, '.locale_selector')

  locale_name = locale_selector.all(:css, 'option').detect { |o| o.value == locale_for_language(new_language) }
  locale_selector.select(locale_name.text) if locale_name
end

When /^I add the (.+) localization of the "(.+)" attribute as "(.+)"$/ do |language, attribute, value|
  # Emulate old find behavior, just use first match. Better would be
  # selecting an element by id.
  attribute_p = page.find(:xpath, "(//span[contains(@class, '#{attribute}_translation')])[1]/..")
  add_link = attribute_p.find(:css, '.add_locale')
  add_link.click
  span = attribute_p.all(:css, ".#{attribute}_translation").last

  update_localization(span, language, value)
end

# Maybe this step can replace 'I change the ... localization of the ... attribute'
When /^I set the (.+) localization of the "(.+)" attribute to "(.+)"$/ do |language, attribute, value|
  locale = locale_for_language language

  # Look for a span with #{attribute}_translation class, which doesn't have an
  # ancestor with style display: none
  span = page.find(:xpath, "//span[contains(@class, '#{attribute}_translation') " +
                    "and not(ancestor-or-self::*[starts-with(normalize-space(substring-after(@style, 'display:')), 'none')])]")
  update_localization(span, language, value)
end

def update_localization(container, language, value)
  new_value = container.find(:css, 'input[type=text], textarea')
  new_locale = container.find(:css, '.locale_selector', visible: false)

  new_value.set(value.gsub('\\n', "\n"))

  locale_name = new_locale.all(:css, 'option', visible: false).detect { |o| o.value == locale_for_language(language) }
  new_locale.select(locale_name.text) if locale_name
end

Then /^the delete link for the (.+) localization of the "(.+)" attribute should not be visible$/ do |locale, attribute_name|
  attribute_span = span_for_localization locale, attribute_name

  attribute_span.find(:css, 'a.destroy_locale', visible: false).should_not be_visible
end

def span_for_localization(language, attribute)
  locale = locale_for_language language

  attribute_spans = page.all(:css, "span.#{attribute}_translation")

  attribute_spans.detect do |attribute_span|
    attribute_span.find(:css, '.locale_selector', visible: false)['value'] == locale &&
      attribute_span.visible?
  end
end

def locale_for_language(language)
  { 'german' => 'de', 'english' => 'en', 'french' => 'fr' }[language]
end

Then(/^I should see "(.*?)" for report "(.*?)"$/) do |link_name, table_value_name|
  within 'table.generic-table' do
    table_data = first('td a', text: table_value_name)
    row = table_data.find(:xpath, '../..')

    expect(row).to have_selector('a', text: link_name)
  end
end

When(/^I follow link "(.*?)" for report "(.*?)"$/) do |link_name, table_value_name|
  within 'table.generic-table' do
    table_data = first('td a', text: table_value_name)
    row = table_data.find(:xpath, '../..')

    row.find('a', text: link_name).click
  end
end

Then(/^I should see button "(.*?)"$/) do |button_name|
  expect(page).to have_selector('span.hidden-for-sighted', text: button_name, visible: false)
end
