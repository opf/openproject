# frozen_string_literal: true

module PDF
  module Core
    class DocumentState #:nodoc:
      def initialize(options)
        normalize_metadata(options)

        @store =
          if options[:print_scaling]
            PDF::Core::ObjectStore.new(
              info: options[:info],
              print_scaling: options[:print_scaling]
            )
          else
            PDF::Core::ObjectStore.new(info: options[:info])
          end

        @version                 = 1.3
        @pages                   = []
        @page                    = nil
        @trailer                 = options.fetch(:trailer, {})
        @compress                = options.fetch(:compress, false)
        @encrypt                 = options.fetch(:encrypt, false)
        @encryption_key          = options[:encryption_key]
        @skip_encoding           = options.fetch(:skip_encoding, false)
        @before_render_callbacks = []
        @on_page_create_callback = nil
      end

      attr_accessor :store, :version, :pages, :page, :trailer, :compress,
        :encrypt, :encryption_key, :skip_encoding,
        :before_render_callbacks, :on_page_create_callback

      def populate_pages_from_store(document)
        return 0 if @store.page_count <= 0 || !@pages.empty?

        count = (1..@store.page_count)
        @pages = count.map do |index|
          orig_dict_id = @store.object_id_for_page(index)
          PDF::Core::Page.new(document, object_id: orig_dict_id)
        end
      end

      def normalize_metadata(options)
        options[:info] ||= {}
        options[:info][:Creator] ||= 'Prawn'
        options[:info][:Producer] ||= 'Prawn'

        options[:info]
      end

      def insert_page(page, page_number)
        pages.insert(page_number, page)
        store.pages.data[:Kids].insert(page_number, page.dictionary)
        store.pages.data[:Count] += 1
      end

      def on_page_create_action(doc)
        on_page_create_callback[doc] if on_page_create_callback
      end

      def before_render_actions(_doc)
        before_render_callbacks.each { |c| c.call(self) }
      end

      def page_count
        pages.length
      end

      def render_body(output)
        store.each do |ref|
          ref.offset = output.size
          output <<
            if @encrypt
              ref.encrypted_object(@encryption_key)
            else
              ref.object
            end
        end
      end
    end
  end
end
