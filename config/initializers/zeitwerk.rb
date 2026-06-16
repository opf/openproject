# frozen_string_literal: true

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

require Rails.root.join("config/constants/open_project/inflector")

OpenProject::Inflector.rule do |_, abspath|
  if abspath.match?(/open_project\/version(\.rb)?\z/) ||
    abspath.match?(/lib\/open_project\/\w+\/version(\.rb)?\z/)
    "VERSION"
  end
end

# The order of the matchers is relevant, as less specific matcher could exclude more specific matchers.
# I.e. `/\Afoo_(.*)_bar\z/` must be specified before `/\Afoo_(.*)\z/` and `/\A(.*)_bar\z/`,
# as only the first matching rule wil be applied.
OpenProject::Inflector.rule do |basename, abspath|
  case basename
  when /\Aoauth_(.*)_api\z/
    "OAuth#{default_inflect($1, abspath)}API"
  when /\Aapi_(.*)\z/
    "API#{default_inflect($1, abspath)}"
  when /\A(.*)_api\z/
    "#{default_inflect($1, abspath)}API"
  when "api"
    "API"
  when /(.*)_ical_(.*)/i
    "#{default_inflect($1, abspath)}ICal#{default_inflect($2, abspath)}"
  when /\Aical_(.*)\z/
    "ICal#{default_inflect($1, abspath)}"
  when /\A(.*)_ical\z/
    "#{default_inflect($1, abspath)}ICal"
  when "ical"
    "ICal"
  when /\Aar_(.*)\z/
    "AR#{default_inflect($1, abspath)}"
  when /\Aoauth_(.*)\z/
    "OAuth#{default_inflect($1, abspath)}"
  when /\A(.*)_oauth\z/
    "#{default_inflect($1, abspath)}OAuth"
  when "openid_connect"
    "OpenIDConnect"
  when "oauth"
    "OAuth"
  when /\Aclamav_(.*)\z/
    "ClamAV#{default_inflect($1, abspath)}"
  when /\A(.*)_sso\z/
    "#{default_inflect($1, abspath)}SSO"
  end
end

# Instruct zeitwerk to 'ignore' all the engine gems' lib initialization files.
# As it is complicated to return all the paths where such an initialization file might exist,
# we simply return the general OpenProject namespace for such files.
OpenProject::Inflector.rule do |_basename, abspath|
  if /\/lib\/openproject-\w+.rb\z/.match?(abspath)
    "OpenProject"
  end
end

OpenProject::Inflector.inflection(
  "rss" => "RSS",
  "sha1" => "SHA1",
  "sso" => "SSO",
  "csv" => "CSV",
  "csv_formula_sanitization" => "CSVFormulaSanitization",
  "pdf" => "PDF",
  "scm" => "SCM",
  "imap" => "IMAP",
  "pop3" => "POP3",
  "cors" => "CORS",
  "openid_connect" => "OpenIDConnect",
  "pdf_export" => "PDFExport",
  "ical" => "ICal",
  "clamav" => "ClamAV"
)

Rails.autoloaders.each do |autoloader|
  autoloader.inflector = OpenProject::Inflector.new(__FILE__)
end

Rails.autoloaders.main.ignore(Rails.root.join("lib/open_project/patches"))
Rails.autoloaders.main.ignore(Rails.root.join("lib/generators"))

# Comment in to enable zeitwerk logging.
# Rails.autoloaders.main.log!
