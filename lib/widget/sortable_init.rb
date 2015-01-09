#-- copyright
# OpenProject Reporting Plugin
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

class Widget::Table::SortableInit < Widget::Base

  def render
    sort_first_row = @options[:sort_first_row] || false

    write (content_tag :script, type: "text/javascript" do
      content = %Q{//<![CDATA[
      var table_date_header = $$('#sortable-table th').first();
      sortables_init(); }.html_safe
      if sort_first_row
        content << %Q{ if (table_date_header.childElements().size() > 0) {
            ts_resortTable(table_date_header.childElements().first(), table_date_header.cellIndex);
          }
        }.html_safe
      end
      content << "//]]>"
    end.html_safe)
  end
end
