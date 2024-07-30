# -- copyright
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
# ++

##
# Intended to be used by the ApplicationController to provide authorization helpers
module Accounts::Authorization
  extend ActiveSupport::Concern

  METHODS_ENFORCING_AUTHORIZATION = %i[require_admin authorize authorize_global load_and_authorize_in_optional_project].freeze

  included do
    class_attribute :authorization_ensured,
                    default: {
                      only: [],
                      except: [],
                      generally_allowed: false,
                      controller: self
                    }
  end

  private

  def authorization_check_required
    unless authorization_is_ensured?(params[:action])
      raise <<-MESSAGE
        Authorization check required for #{self.class.name}##{params[:action]}.

        Use any method of
          #{METHODS_ENFORCING_AUTHORIZATION.join(', ')}
        to ensure authorization. If authorization is checked by any other means,
        affirm the same by calling 'authorization_checked!' in the controller. If the authorization does
        not need to be checked for this action, affirm the same by calling 'no_authorization_required!'
      MESSAGE
    end
  end

  # Authorize the user for the requested controller action.
  # To be used in before_action hooks
  def authorize
    do_authorize({ controller: params[:controller], action: params[:action] }, global: false)
  end

  # Authorize the user for the requested controller action outside a project
  # To be used in before_action hooks
  def authorize_global
    do_authorize({ controller: params[:controller], action: params[:action] }, global: true)
  end

  # Find a project based on params[:project_id]
  def load_and_authorize_in_optional_project
    @project = Project.find(params[:project_id]) if params[:project_id].present?

    do_authorize({ controller: params[:controller], action: params[:action] }, global: params[:project_id].blank?)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Deny access if user is not allowed to do the specified action.
  #
  # Action can be:
  # * a parameter-like Hash (eg. { controller: '/projects', action: 'edit' })
  # * a permission Symbol (eg. :edit_project)
  def do_authorize(action, global: false) # rubocop:disable Metrics/PerceivedComplexity
    is_authorized = if global
                      User.current.allowed_based_on_permission_context?(action)
                    else
                      User.current.allowed_based_on_permission_context?(action,
                                                                        project: @project || @projects,
                                                                        entity: @work_package || @work_packages)
                    end

    unless is_authorized
      if @project&.archived?
        render_403 message: :notice_not_authorized_archived_project
      else
        deny_access
      end
    end
    is_authorized
  end

  def require_admin
    return unless require_login

    render_403 unless current_user.admin?
  end

  def authorization_is_ensured?(action)
    return false if authorization_ensured.nil?

    (authorization_ensured[:generally_allowed] == true || authorization_ensured[:only].include?(action.to_sym)) &&
      authorization_ensured[:except].exclude?(action.to_sym)
  end

  class_methods do
    # Overriding before_action of rails to check if any authorization method is by now defined.
    def before_action(*names, &)
      set_authorization_checked_if_covered(*names)

      super
    end

    def prepend_before_action(*names, &)
      set_authorization_checked_if_covered(*names)

      super
    end

    def append_before_action(*names, &)
      set_authorization_checked_if_covered(*names)

      super
    end

    def set_authorization_checked_if_covered(*names)
      return unless METHODS_ENFORCING_AUTHORIZATION.intersect?(names)

      authorization_checked_by_default_action(only: names.last.is_a?(Hash) ? Array(names.last[:only]) : [],
                                              except: names.last.is_a?(Hash) ? Array(names.last[:except]) : [])
    end

    def no_authorization_required!(*actions)
      raise ArgumentError, "no_authorization_required! needs to have actions specified" unless actions.any?

      authorization_checked_by_default_action(only: actions)
    end

    alias :authorization_checked! :no_authorization_required!

    def authorization_checked_by_default_action(only: [], except: [])
      # A class_attribute is used so that inheritance works also for defined only/except actions.
      # But since the only/accept arrays are only modified in place, the same object would be used from the
      # ApplicationController downwards. So whenever it is detected that the controller the authorization_ensured
      # object is defined for changes, we clone it so that henceforth all changes are local.
      clone_authorization_ensured unless self == authorization_ensured[:controller]

      if only.any? || except.any?
        update_authorization_ensured_on_actions(only:, except:)
      else
        update_authorization_ensured_on_all
      end
    end

    def update_authorization_ensured_on_actions(only: [], except: [])
      update_authorization_ensured_on_action_only(only)
      update_authorization_ensured_on_action_except(only, except)
    end

    def update_authorization_ensured_on_action_only(only)
      if only.any?
        authorization_ensured[:only] += only
        authorization_ensured[:only].uniq!
      else
        update_authorization_ensured_on_all
      end
    end

    def update_authorization_ensured_on_action_except(only, except)
      authorization_ensured[:except] += except - authorization_ensured[:only] if except.any?
      authorization_ensured[:except] -= only if only.any?
      authorization_ensured[:except].uniq!
    end

    def update_authorization_ensured_on_all
      authorization_ensured[:generally_allowed] = true
    end

    def clone_authorization_ensured
      self.authorization_ensured = { only: authorization_ensured[:only].dup,
                                     except: authorization_ensured[:except].dup,
                                     generally_allowed: authorization_ensured[:generally_allowed],
                                     controller: self }
    end
  end
end
