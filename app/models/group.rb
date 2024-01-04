#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class Group < Principal
  include ::Scopes::Scoped

  has_many :group_users,
           autosave: true,
           dependent: :destroy

  has_many :users,
           through: :group_users,
           before_add: :fail_add

  acts_as_customizable

  alias_attribute(:name, :lastname)
  validates :name, presence: true
  validate :uniqueness_of_name
  validates :name, length: { maximum: 256 }

  # HACK: We want to have the :preference association on the Principal to allow
  # for eager loading preferences.
  # However, the preferences are currently very user specific.  We therefore
  # remove the methods added by
  #   has_one :preference
  # to avoid accidental assignment and usage of preferences on groups.
  undef_method :preference,
               :preference=,
               :build_preference,
               :create_preference,
               :create_preference!

  scopes :visible

  def to_s
    lastname
  end

  private

  def uniqueness_of_name
    groups_with_name = Group.where('lastname = ? AND id <> ?', name, id || 0).count
    if groups_with_name > 0
      errors.add :name, :taken
    end
  end

  def fail_add
    fail "Do not add users through association, use `Groups::AddUsersService` instead."
  end
end
