#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

module ErrorMessageHelper
  def error_messages_for(*params)
    objects, options = extract_objects_from_params(params)

    error_messages = objects.map { |o| o.errors.full_messages }.flatten

    render_error_messages_partial(error_messages, options[:object])
  end

  # Will take a contract to display the errors in a rails form.
  # In order to have faulty field highlighted, the method sets
  # all errors in the contract on the object as well.
  def error_messages_for_contract(object, errors)
    return unless errors

    error_messages = errors.full_messages

    errors.details.each do |attribute, details|
      details.map { |d| d[:error] }.flatten.each do |message|
        object.errors.add(attribute, message)
      end
    end

    render_error_messages_partial(error_messages, object)
  end

  def extract_objects_from_params(params)
    options = params.extract_options!.symbolize_keys

    objects = Array.wrap(options.delete(:object) || params).map do |object|
      object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
      object = convert_to_model(object)
      options[:object] ||= object

      object
    end

    [objects.compact, options]
  end

  def render_error_messages_partial(messages, object)
    unless messages.empty?
      render partial: 'common/validation_error',
             locals: { error_messages: messages,
                       object_name:  object.class.model_name.human }
    end
  end
end
