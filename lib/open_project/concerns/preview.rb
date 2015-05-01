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

################################################################################
# This concern provides a general implementation of preview functionality      #
# found in different controllers.                                              #
#                                                                              #
# Nevertheless, this concern expects the controller to implement the function  #
# #parse_preview_data. #parse_preview_data must return a list of (wiki) texts, #
# attachments required to render the texts, and the object. Attachments and    #
# object may be nil.                                                           #
#                                                                              #
# You may use #parse_preview_data_helper to implement #parse_preview_data.     #
# Then, a minimal implementation of #parse_preview_data may looks as follows:  #
#                                                                              #
# def parse_preview_data                                                       #
#   parse_preview_data_helper :work_packages, [:description, :notes]           #
# end                                                                          #
#                                                                              #
# The first parameter 'param_name' specifies the key in the params object that #
# contains the values. The second parameter 'attributes' specifies the value   #
# keys. Optionally, if 'param_name' is not equivalent to a class name, you     #
# can pass the objects class as third parameter.                               #
#                                                                              #
# For object identification #parse_preview_data_helper uses the params         #
# object's 'id' key, if available. If 'id' needs some preprocessing or is not  #
# the id to the object instance, you may override #parse_preview_id to provide #
# a different id.                                                              #
################################################################################
module OpenProject::Concerns::Preview
  extend ActiveSupport::Concern

  def preview
    texts, attachments, obj = parse_preview_data

    if obj.nil? || authorize_previewed_object(obj)
      render 'common/preview',
             layout: false,
             locals: { texts: texts, attachments: attachments, previewed: obj }
    end
  end

  protected

  def parse_preview_data_helper(param_name, attributes, klass = nil)
    klass ||= param_name.to_s.classify.constantize

    texts = Array(attributes).each_with_object({}) do |attribute, list|
      caption = (attribute == :notes) ? Journal.human_attribute_name(:notes)
                                      : klass.human_attribute_name(attribute)
      text = params[param_name][attribute]
      list[caption] = text
    end

    obj = parse_previewed_object(klass)

    attachments = previewed_object_attachments(obj)

    [texts, attachments, obj]
  end

  private

  def parse_previewed_object(klass)
    id = parse_previewed_id
    id ? klass.find_by_id(id) : nil
  end

  def parse_previewed_id
    params[:id]
  end

  def authorize_previewed_object(obj)
    @project = obj.project
    authorize
  end

  def previewed_object_attachments(obj)
    is_attachable = obj && (obj.respond_to?('attachable') || obj.respond_to?('attachments'))

    is_attachable ? obj.attachments : nil
  end
end
