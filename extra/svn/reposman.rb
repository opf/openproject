#!/usr/bin/env ruby
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

warn <<~EOS
    [DEPRECATION] The functionality provided by reposman.rb has been integrated into OpenProject.
    Please remove any existing cronjobs that still use this script.
  #{'  '}
    You can create repositories explicitly on the filesystem using managed repositories.
    Enable managed repositories for each SCM vendor individually using the templates
    defined in configuration.yml.
  #{'  '}
    If you want to convert existing repositories previously created (by reposman.rb or manually)
    into managed repositories, use the following command:
  #{'  '}
        $ bundle exec rake scm:migrate:managed[URL prefix (, URL prefix, ...)]
    Where URL prefix denotes a common prefix of repositories whose status should be upgraded to :managed.
    Example:
  #{'  '}
    If you have executed reposman.rb with the following parameters:
  #{'  '}
      $ reposman.rb [...] --svn-dir "/opt/svn" --url "file:///opt/svn"
  #{'  '}
    Then you can pass a URL prefix of 'file:///opt/svn' and the rake task will migrate all repositories
    matching this prefix to :managed.
    You may pass more than one URL prefix to the task.
EOS
