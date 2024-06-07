# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

  METHODS_ENFORCING_AUTHORIZATION = %i[require_admin authorize authorize_global authorize_in_optional_project].freeze

  included do
    class_attribute :authorization_ensured,
                    default: {
                      only: [],
                      except: [],
                      generally_allowed: false,
                      controller: self
                    }
  end

  def require_admin
    return unless require_login

    render_403 unless current_user.admin?
  end

  def authorization_check_required
    unless authorization_is_ensured?(params[:action])
      if Rails.env.development?
        raise <<-MESSAGE
          Authorization check required for #{params[:action]} in #{self.class.name}.

          Use any method of 'authorize', 'authorize_global', 'authorize_in_optional_project'
          or 'require_admin' to ensure authorization. If authorization is checked by any other means,
          affirm the same by calling 'authorization_checked!' in the controller. If the authorization does
          not need to be checked for this action, affirm the same by calling 'no_authorization_required!'
        MESSAGE
      else
        render_403
      end
    end
  end

  private

  def authorization_is_ensured?(action)
    return false if authorization_ensured.nil?

    (authorization_ensured[:generally_allowed] == true || authorization_ensured[:only].include?(action.to_sym)) &&
      authorization_ensured[:except].exclude?(action.to_sym)
  end

  class_methods do
    # Overriding before_action of rails to check if any authorization method is by now defined.
    def before_action(*names, &)
      if METHODS_ENFORCING_AUTHORIZATION.intersect?(names)
        no_authorization_required!(only: names.last.is_a?(Hash) ? Array(names.last[:only]) : [],
                                   except: names.last.is_a?(Hash) ? Array(names.last[:except]) : [])
      end

      super
    end

    def no_authorization_required!(only: [], except: [])
      only = Array(only)
      except = Array(except)

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

    alias :authorization_checked! :no_authorization_required!

    def update_authorization_ensured_on_actions(only: [], except: [])
      update_authorization_ensured_on_action_only(only)
      update_authorization_ensured_on_action_except(only, except)
    end

    def update_authorization_ensured_on_action_only(only)
      authorization_ensured[:generally_allowed] = true if only.empty?

      if only.any?
        authorization_ensured[:only] += only
        authorization_ensured[:only].uniq!
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
