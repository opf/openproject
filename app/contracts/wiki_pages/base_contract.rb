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

# Validates both the wiki page as well as its associated wiki content. The two are
# considered to be one outside of this contract.
module WikiPages
  class BaseContract < ::ModelContract
    attribute :wiki
    attribute :title
    attribute :slug
    attribute :parent
    attribute :text
    attribute :protected

    validate :validate_author_is_set
    validate :validate_wiki_is_set
    validate :validate_user_edit_allowed
    validate :validate_user_protect_permission

    private

    def validate_user_edit_allowed
      if (model.project && !user.allowed_in_project?(:edit_wiki_pages, model.project)) ||
         (model.protected_was && !user.allowed_in_project?(:protect_wiki_pages, model.project))
        errors.add :base, :error_unauthorized
      end
    end

    def validate_author_is_set
      errors.add :author, :blank if model.author.nil?
    end

    def validate_wiki_is_set
      errors.add :wiki, :blank if model.wiki.nil?
    end

    def validate_user_protect_permission
      if model.protected_changed? && !user.allowed_in_project?(:protect_wiki_pages, model.project)
        errors.add :protected, :error_unauthorized
      end
    end
  end
end
