#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module CostlogHelper
  include TimelogHelper

  def render_costlog_breadcrumb
    links = []
    links << link_to(l(:label_project_all), project_id: nil, work_package_id: nil)
    links << link_to(h(@project), project_id: @project, work_package_id: nil) if @project
    links << link_to_work_package(@work_package, subject: false) if @work_package
    breadcrumb links
  end

  def cost_types_collection_for_select_options(selected_type = nil)
    cost_types = CostType.active.sort

    if selected_type && !cost_types.include?(selected_type)
      cost_types << selected_type
      cost_types.sort
    end
    collection = []
    collection << ["--- #{l(:actionview_instancetag_blank_option)} ---", ''] unless cost_types.detect(&:is_default?)
    cost_types.each do |t| collection << [t.name, t.id] end
    collection
  end

  def user_collection_for_select_options(_options = {})
    users = @project.possible_assignees
    collection = []
    users.each do |u| collection << [u.name, u.id] end
    collection
  end

  def extended_progress_bar(pcts, options = {})
    return progress_bar(pcts, options) unless pcts.is_a?(Numeric) && pcts > 100

    width = options[:width] || '100px;'
    legend = options[:legend] || ''
    content_tag('table',
                content_tag('tr',
                            content_tag('td', '', style: "width: #{((100.0 / pcts) * 100).round}%;", class: 'closed') +
                            content_tag('td', '', style: "width: #{100.0 - ((100.0 / pcts) * 100).round}%;", class: 'exceeded')
                           ), class: 'progress', style: "width: #{width};") +
      content_tag('p', legend, class: 'pourcent')
  end

  def clean_currency(value)
    return nil if value.nil? || value == ''

    value = value.strip
    value.gsub!(l(:currency_delimiter), '') if value.include?(l(:currency_delimiter)) && value.include?(l(:currency_separator))
    value.gsub(',', '.')
    BigDecimal.new(value)
  end

  def to_currency_with_empty(rate)
    rate.nil? ?
      '0.0' :
      number_to_currency(rate.rate)
  end
end
