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

module ErrorsHelper
  def render_400(options = {}) # rubocop:disable Naming/VariableNumber
    unset_template_magic
    render_error({ message: :notice_bad_request, status: 400 }.merge(options))
    false
  end

  def render_403(options = {}) # rubocop:disable Naming/VariableNumber
    unset_template_magic
    render_error({ message: :notice_not_authorized, status: 403 }.merge(options))
    false
  end

  def render_404(options = {}) # rubocop:disable Naming/VariableNumber
    render_error({ message: :notice_file_not_found, status: 404 }.merge(options))
    false
  end

  def render_500(options = {}) # rubocop:disable Naming/VariableNumber
    unset_template_magic

    message = t(:notice_internal_server_error, app_title: Setting.app_title)

    # Append error information
    if current_user.admin?
      options[:message_details] = get_additional_message
    end

    render_error({ message:, status: 500 }.merge(options))
    false
  end

  def get_additional_message
    return unless OpenProject::Configuration.migration_check_on_exceptions?

    if OpenProject::Database.migrations_pending?(ensure_fresh: true)
      I18n.t(:error_migrations_are_pending)
    end
  end

  def render_optional_error_file(status_code)
    user_setup unless User.current.id == session[:user_id]

    case status_code
    when :not_found
      render_404
    when :internal_server_error
      render_500
    else
      super
    end
  end

  # Renders an error response
  def render_error(arg) # rubocop:disable Metrics/AbcSize
    arg = { message: arg } unless arg.is_a?(Hash)

    status = arg[:status] || 500
    message = arg[:message]

    if status >= 500
      op_handle_error(arg[:exception] || "[Error #status] #message", payload: arg[:payload])
    end

    message = I18n.t(message) if message.is_a?(Symbol)
    message_details = arg[:message_details]
    respond_to do |format|
      format.html do
        error_message = "[#{I18n.t(:error_code, code: status)}] #{message}\n#{message_details}"
        flash.now[:error] = { message: error_message, dismiss_scheme: :none }
        render template: "common/error",
               layout: use_layout,
               status:,
               locals: { status:, params: }
      end
      format.any do
        head status
      end
    end
  end

  def unset_template_magic
    @project = nil # rubocop:disable Rails/HelperInstanceVariable
  end
end
