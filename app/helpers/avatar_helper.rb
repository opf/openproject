#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module AvatarHelper
  include GravatarHelper::PublicMethods

  # Returns the avatar image tag for the given +user+ if avatars are enabled
  # +user+ can be a User or a string that will be scanned for an email address (eg. 'joe <joe@foo.bar>')
  def avatar(user, options = { })
    avatar = if Setting.gravatar_enabled? && (email = extract_email_address(user)).present?
               options.merge!({ :ssl => (defined?(request) && request.ssl?),
                                :default => Setting.gravatar_default })

               gravatar(email.to_s.downcase, options)
             end
  ensure
    # return is actually needed here
    return (avatar || ''.html_safe)
  end

  private

  def extract_email_address(object)
    if object.respond_to?(:mail)
      object.mail
    elsif object.to_s =~ %r{<(.+?)>}
      $1
    end
  end
end
