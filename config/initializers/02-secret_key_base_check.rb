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

# Refuse to boot in production if SECRET_KEY_BASE is a known-weak default that
# we have shipped in our Dockerfile or referenced in our documentation.
# An attacker who knows the secret can forge signed cookies and session data
# and decrypt anything derived from it.
insecure_secret_key_bases = [
  "OVERWRITE_ME", # default value in Dockerfile
  "secret", # old sample from documentation
  "<your-secret-key-base>" # new sample from documentation
].freeze

no_rake_task = !(Rake.respond_to?(:application) && Rake.application.top_level_tasks.present?)
no_override = ENV["OPENPROJECT_DISABLE__SECRET_KEY_BASE__CHECK"] != "true"
if Rails.env.production? && no_rake_task && no_override
  secret = ENV["SECRET_KEY_BASE"].to_s
  fatal_reason =
    if secret.empty?
      "SECRET_KEY_BASE is not set."
    elsif insecure_secret_key_bases.include?(secret)
      "SECRET_KEY_BASE is set to a well-known default value (#{secret.inspect})."
    end

  if fatal_reason
    abort <<~ERROR # rubocop:disable Rails/Exit
      ======= INSECURE SECRET_KEY_BASE DETECTED =======
      #{fatal_reason}

      OpenProject uses SECRET_KEY_BASE to sign cookies, sessions, and other
      security-sensitive data. Running with a default or weak value allows
      anyone to forge signed data and compromise the installation.

      Generate a strong, random value (for example via `openssl rand -hex 64`)
      and provide it via the SECRET_KEY_BASE environment variable. The same
      value MUST be reused on every container/process start, otherwise
      existing sessions and encrypted database content become unreadable.

      If you know what you are doing and want to disable this check, set the environment
      variable OPENPROJECT_DISABLE__SECRET_KEY_BASE__CHECK to "true" (not recommended).

      Documentation:
      - https://www.openproject.org/docs/installation-and-operations/installation/docker/

      =================================================
    ERROR
  end
end
