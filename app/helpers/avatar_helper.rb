#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'gravatar_image_tag'

module AvatarHelper
  include GravatarImageTag

  GravatarImageTag.configure do |c|
    c.include_size_attributes = false
    c.secure = Setting.protocol == 'https'
    c.default_image = Setting.gravatar_default.blank? ? nil : Setting.gravatar_default
  end

  Setting.register_callback(:protocol) do |values|
    GravatarImageTag.configure do |c|
      c.secure = values[:value] == 'https'
    end
  end

  Setting.register_callback(:gravatar_default) do |values|
    GravatarImageTag.configure do |c|
      c.default_image = values[:value].blank? ? nil : values[:value]
    end
  end

  def self.secure?
    GravatarImageTag.configuration.secure
  end

  def self.default
    GravatarImageTag.configuration.default_image
  end

  # Returns the avatar image tag for the given +user+ if avatars are enabled
  # +user+ can be a User or a string that will be scanned for an email address (eg. 'joe <joe@foo.bar>')
  def avatar(user, options = {})
    avatar = with_default_avatar_options(user, options) do |email, opts|
      tag_options = merge_image_options(user, opts)

      gravatar_image_tag(email, tag_options)
    end
  ensure # return is actually needed here
    return (avatar || ''.html_safe)
  end

  def avatar_url(user, options = {})
    url = with_default_avatar_options(user, options) do |email, opts|
      gravatar_image_url(email, opts)
    end
  ensure # return is actually needed here
    return (url || ''.html_safe)
  end

  private

  def merge_image_options(user, options)
    default_options = { class: 'avatar' }
    default_options[:title] = h(user.name) if user.respond_to?(:name)

    options.reverse_merge(default_options)
  end

  def with_default_avatar_options(user, options, &block)
    if options.delete(:size)
      warn <<-DOC

        [DEPRECATION] The :size option is no longer supported for #avatar.
        Use css styling (:class attribute). The classes '.avatar', '.gravatar', and '.avatar-mini' are provided for this
        Called from #{caller[1]}
      DOC
    end

    if Setting.gravatar_enabled? && (email = extract_email_address(user)).present?
      block.call(email.to_s.downcase, options)
    end
  end

  def extract_email_address(object)
    if object.respond_to?(:mail)
      object.mail
    elsif object.to_s =~ %r{<(.+?)>}
      $1
    end
  end
end
