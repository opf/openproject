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

# Handles setting the attributes of a wiki page.
# The wiki page is treated as one single entity although the data layer separates
# between the page and the content.
#
# In the long run, those two should probably be unified on the data layer as well.
#
# Attributes for both the page as well as for the content are accepted.
class WikiPages::SetAttributesService < ::BaseServices::SetAttributes
  include Attachments::SetReplacements

  private

  def set_attributes(params)
    content_params, page_params = split_page_and_content_params(params.with_indifferent_access)

    set_page_attributes(page_params)

    set_default_attributes(params) if model.new_record?

    set_content_attributes(content_params)
  end

  def set_page_attributes(params)
    model.attributes = params
  end

  def set_default_attributes(_params)
    model.build_content page: model
    model.content.extend(OpenProject::ChangedBySystem)

    model.content.change_by_system do
      model.content.author = user
    end
  end

  def set_content_attributes(params)
    model.content.attributes = params
  end

  def split_page_and_content_params(params)
    params.partition { |p, _| content_attribute?(p) }.map(&:to_h)
  end

  def content_attribute?(name)
    WikiContent.column_names.include?(name) || name.to_s == 'comments'
  end
end
