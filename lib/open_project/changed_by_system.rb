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

# OpenProject in its contracts has checks to govern which attributes are writable. Only attributes marked to be
# writable, can be set by a user.
# In some scenarios however, the system needs to set calculated attributes, e.g. if a default value is set - the current user
# becomes the author of the work package.
#
# While an attribute should not be marked as writable, is sometimes still needs to be changed, thus.
# Such attributes can be changed using this module.
#
# The flow would be
#
#   # The model is an AR class like work package
#   model.extend(OpenProject::ChangedBySystem)
#   model.change_by_system do
#     model.author = current_user
#   end
#
# The contract checking later on can then query for
#
#  model.changed_by_system
#
# This method will return the changes carried out inside a change_by_system block. It returns a hash of all the
# changed attributes as well as the value it was changed from and the value it was changed to.
#
# Querying
#
#   model.changed_by_user
#
# will return all attributes changed by the user instead.

module OpenProject
  module ChangedBySystem
    def changed_by_system(attributes = nil)
      @changed_by_system ||= {}

      if attributes
        @changed_by_system.merge!(attributes)
      end

      @changed_by_system
    end

    # Wrapper to track changes carried out in the context of the system.
    #
    #   model.change_by_system do
    #     model.attribute = 1
    #   end
    #
    # Attribute changes carried out within such a scope will not count to be changed
    # by the user. It can therefore be used to set calculated or default values.
    #
    # This should never be used with user provided values.
    #
    # No only the attribute is tracked but also the values. So it is safe to e.g. first
    # set a default value, and then mass assign attributes. If the default value is overwritten
    # by the mass assignment the change in value will give that away.
    def change_by_system
      prior_changes = non_no_op_changes

      ret = yield

      changed_by_system(changes_compared_to(prior_changes))

      ret
    end

    # Similar to #changed from ActiveRecord this returns all attributes that are
    # currently changed. But it will only include those attributes, that have not
    # been changed within a #change_by_system block and as such are caused by user input.
    def changed_by_user
      (model_changes.reject { |key, change| changed_by_system[key] == change }).keys
    end

    private

    def non_no_op_changes
      model_changes.reject { |_, (old, new)| old == 0 && new.nil? }
    end

    def changes_compared_to(prior_changes)
      model_changes.select { |c| !prior_changes[c] || prior_changes[c].last != model_changes[c].last }
    end

    # Construct the custom model changes method, which is based on the `ActiveRecord::Base#changes`.
    # Includes the changes of the custom fields, if the object extends the acts_as_customizable
    # (Redmine::Acts::Customizable::InstanceMethods) plugin.
    # Ideally we would override the `ActiveRecord::Base#changes`, but adding the custom field attributes
    # to the `ActiveRecord::Base#changes` may produce some unwanted side effects.
    def model_changes
      changes.tap do |c|
        c.merge!(custom_field_changes) if respond_to?(:custom_field_changes)
        c
      end
    end
  end
end
