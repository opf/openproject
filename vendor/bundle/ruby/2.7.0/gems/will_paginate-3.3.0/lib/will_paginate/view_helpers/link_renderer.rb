require 'cgi'
require 'will_paginate/core_ext'
require 'will_paginate/view_helpers'
require 'will_paginate/view_helpers/link_renderer_base'

module WillPaginate
  module ViewHelpers
    # This class does the heavy lifting of actually building the pagination
    # links. It is used by +will_paginate+ helper internally.
    class LinkRenderer < LinkRendererBase
      
      # * +collection+ is a WillPaginate::Collection instance or any other object
      #   that conforms to that API
      # * +options+ are forwarded from +will_paginate+ view helper
      # * +template+ is the reference to the template being rendered
      def prepare(collection, options, template)
        super(collection, options)
        @template = template
        @container_attributes = @base_url_params = nil
      end

      # Process it! This method returns the complete HTML string which contains
      # pagination links. Feel free to subclass LinkRenderer and change this
      # method as you see fit.
      def to_html
        html = pagination.map do |item|
          item.is_a?(Integer) ?
            page_number(item) :
            send(item)
        end.join(@options[:link_separator])
        
        @options[:container] ? html_container(html) : html
      end

      # Returns the subset of +options+ this instance was initialized with that
      # represent HTML attributes for the container element of pagination links.
      def container_attributes
        @container_attributes ||= {
          :role => 'navigation',
          :"aria-label" => @template.will_paginate_translate(:container_aria_label) { 'Pagination' }
        }.update @options.except(*(ViewHelpers.pagination_options.keys + [:renderer] - [:class]))
      end
      
    protected
    
      def page_number(page)
        aria_label = @template.will_paginate_translate(:page_aria_label, :page => page.to_i) { "Page #{page}" }
        if page == current_page
          tag(:em, page, :class => 'current', :"aria-label" => aria_label, :"aria-current" => 'page')
        else
          link(page, page, :rel => rel_value(page), :"aria-label" => aria_label)
        end
      end
      
      def gap
        text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
        %(<span class="gap">#{text}</span>)
      end
      
      def previous_page
        num = @collection.current_page > 1 && @collection.current_page - 1
        previous_or_next_page(num, @options[:previous_label], 'previous_page')
      end
      
      def next_page
        num = @collection.current_page < total_pages && @collection.current_page + 1
        previous_or_next_page(num, @options[:next_label], 'next_page')
      end
      
      def previous_or_next_page(page, text, classname)
        if page
          link(text, page, :class => classname)
        else
          tag(:span, text, :class => classname + ' disabled')
        end
      end
      
      def html_container(html)
        tag(:div, html, container_attributes)
      end
      
      # Returns URL params for +page_link_or_span+, taking the current GET params
      # and <tt>:params</tt> option into account.
      def url(page)
        raise NotImplementedError
      end
      
    private

      def param_name
        @options[:param_name].to_s
      end

      def link(text, target, attributes = {})
        if target.is_a?(Integer)
          attributes[:rel] = rel_value(target)
          target = url(target)
        end
        attributes[:href] = target
        tag(:a, text, attributes)
      end
      
      def tag(name, value, attributes = {})
        string_attributes = attributes.inject('') do |attrs, pair|
          unless pair.last.nil?
            attrs << %( #{pair.first}="#{CGI::escapeHTML(pair.last.to_s)}")
          end
          attrs
        end
        "<#{name}#{string_attributes}>#{value}</#{name}>"
      end

      def rel_value(page)
        case page
        when @collection.current_page - 1; 'prev'
        when @collection.current_page + 1; 'next'
        end
      end

      def symbolized_update(target, other, blacklist = nil)
        other.each_pair do |key, value|
          key = key.to_sym
          existing = target[key]
          next if blacklist && blacklist.include?(key)

          if value.respond_to?(:each_pair) and (existing.is_a?(Hash) or existing.nil?)
            symbolized_update(existing || (target[key] = {}), value)
          else
            target[key] = value
          end
        end
      end
    end
  end
end
