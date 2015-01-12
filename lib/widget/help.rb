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

##
# Usage: render_widget Widget::Help, :text
#
# Where :text is a i18n key.
class Widget::Help < Widget::Base
  dont_cache!

  def render
    id = "tip:#{@subject}"
    options = { icon: {}, tooltip: {} }
    options.merge!(yield) if block_given?
    sai = options[:show_at_id] ? ", show_at_id: '#{options[:show_at_id]}'" : ''

    icon = tag :img, src: image_path('reporting_engine/icon_info_red.gif'), id: "target:#{@subject}", alt: ''
    tip = content_tag_string :span, l(@subject), tip_config(options[:tooltip]), false
    script = content_tag :script,
                         "new Tooltip('target:#{@subject}', 'tip:#{@subject}', {className: 'tooltip'#{sai}});",
                         { type: 'text/javascript' }, false
    target = content_tag :a, icon + tip, icon_config(options[:icon])
    write(target + script)
  end

  def icon_config(options)
    add_class = lambda do |cl|
      if cl
        "help #{cl}"
      else
        'help'
      end
    end
    options.mega_merge! href: '#', class: add_class
  end

  def tip_config(options)
    add_class = lambda do |cl|
      if cl
        "#{cl} tooltip"
      else
        'tooltip'
      end
    end
    options.mega_merge! id: "tip:#{@subject}", class: add_class
  end
end

class Hash
  def mega_merge!(hash)
    hash.each do |key, value|
      if value.is_a?(Proc)
        self[key] = value.call(self[key])
      else
        self[key] = value
      end
    end
    self
  end
end
