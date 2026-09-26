# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
# Copyright (C) the OpenProject GmbH
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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

class CreateGitlabCommits < ActiveRecord::Migration[8.1]
  def change
    create_table :gitlab_commits do |t|
      t.references :gitlab_user

      t.string :sha, null: false
      t.text :message, null: false, default: ""
      t.string :author_name, null: false
      t.string :author_email, null: false
      t.datetime :authored_at, null: false, precision: nil
      t.string :repository, null: false
      t.string :gitlab_html_url, null: false

      t.timestamps precision: nil
    end
  end
end
