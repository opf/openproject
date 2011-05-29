module Redmine
  module Views
    class OtherFormatsBuilder
      def initialize(view)
        @view = view
      end
      
      def link_to(name, options={})
        url = { :format => name.to_s.downcase }.merge(options.delete(:url) || {})
        caption = options.delete(:caption) || name
        html_options = { :class => name.to_s.downcase, :rel => 'nofollow' }.merge(options)
        @view.content_tag('span', @view.link_to(caption, url, html_options))
      end
    end
  end
end
