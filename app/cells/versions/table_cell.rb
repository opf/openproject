module Versions
  class TableCell < ::TableCell
    columns :name, :project, :start_date, :effective_date, :description, :status, :sharing, :wiki_page_title

    def sortable?
      false
    end

    def headers
      columns.reject { |col| col == :wiki_page_title }.map do |name|
        [name.to_s, header_options(name)]
      end + [wiki_page_header_options]
    end

    def header_options(name)
      { caption: Version.human_attribute_name(name) }
    end

    def wiki_page_header_options
      ['wiki_page_title', { caption: WikiPage.model_name.human }]
    end
  end
end
