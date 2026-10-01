# frozen_string_literal: true

# Shared authorization logic for controllers that manage user working times.
#
# Allows access when the current user has either:
#   - the global `manage_working_times` permission (can manage any user), or
#   - the global `manage_own_working_times` permission and the target user is themselves.
#
# Requires `@user` to be set before this runs (i.e. `find_user` must precede it
# in the before_action chain).
module WorkingTimesAuthorization
  extend ActiveSupport::Concern

  private

  def authorize_manage_working_times
    return if current_user.allowed_globally?(:manage_working_times)
    return if current_user.allowed_globally?(:manage_own_working_times) && @user == current_user

    deny_access
  end
end
