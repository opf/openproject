#-- copyright
# ReportingEngine
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
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

class Widget::Settings::Fieldset < Widget::Base
  dont_cache!

  def render_with_options(options, &block)
    @type = options.delete(:type) || 'filter'
    @id = "#{@type}"
    @label = :"label_#{@type}"
    super(options, &block)
  end

  def render
    hash = self.hash
    write(content_tag(:fieldset,
                      id: @id,
                      class: 'form--fieldset -collapsible') do
            html = content_tag(:legend,
                               show_at_id: hash.to_s,
                               icon: "#{@type}-legend-icon",
                               tooltip: "#{@type}-legend-tip",
                               class: 'form--fieldset-legend',
                               id: hash.to_s) do
              content_tag(:a, href: '#') do l(@label) end
            end
            html + yield
          end)
  end
end
