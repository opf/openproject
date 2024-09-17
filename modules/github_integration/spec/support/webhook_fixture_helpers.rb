#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "json"

module WebhookFixtureHelpers
  FIXTURES_PATH = File.join(File.dirname(__FILE__), "../fixtures/github_webhooks")

  # Params:
  # * replacements: A `Hash` containing replacement values for placeholders in the fixture files,
  #   usually:
  #   ```
  #   {
  #     title: "A PR title",
  #     body: "A PR body",
  #   }
  #   ```
  def webhook_payload(event, name, replacements = {})
    replacements = replacements.map { |key, value| ["${#{key}}", value.gsub("\n", '\n')] }.to_h
    content = File.read(File.join(FIXTURES_PATH, "#{event}/#{name}.json"))
    content.gsub!(/\$\{[^{]+?\}/, replacements)
    JSON.parse(content)
  end
end

RSpec.configure do |config|
  config.include WebhookFixtureHelpers
end
