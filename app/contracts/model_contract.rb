#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_relative './base_contract'

##
# Model contract for AR records that
# support change tracking
class ModelContract < BaseContract
  def valid?(*_args)
    super()
    readonly_attributes_unchanged

    # Allow subclasses to check only contract errors
    return errors.empty? unless validate_model?

    model.valid?

    # We need to merge the contract errors with the model errors in
    # order to have them available at one place.
    # This is something we need as long as we have validations split
    # among the model and its contract.
    errors.merge!(model.errors)

    errors.empty?
  end

  protected

  ##
  # Allow subclasses to disable model validation
  # during contract validation.
  #
  # This is necessary during, e.g., deletion contract validations
  # to ensure invalid models can be deleted when allowed.
  def validate_model?
    true
  end

  private

  def readonly_attributes_unchanged
    unauthenticated_changed.each do |attribute|
      outside_attribute = collect_ancestor_attribute_aliases[attribute] || attribute

      errors.add outside_attribute, :error_readonly
    end
  end

  def unauthenticated_changed
    changed_by_user - writable_attributes
  end

  def changed_by_user
    model.respond_to?(:changed_by_user) ? model.changed_by_user : model.changed
  end
end
