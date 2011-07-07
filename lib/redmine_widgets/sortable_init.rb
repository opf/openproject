class Widget::Table::SortableInit < Widget::Base

  def render
    sort_first_row = @options[:sort_first_row] || false

    write (content_tag :script, :type => "text/javascript" do
      content = %Q{//<![CDATA[
      var table_date_header = $$('#sortable-table th').first();
      sortables_init(); }.html_safe
      if sort_first_row
        content << %Q{ if (table_date_header.childElements().size() > 0) {
            ts_resortTable(table_date_header.childElements().first(), table_date_header.cellIndex);
          }
        }
      end
      content << "//]]>"
    end.html_safe)
  end
end