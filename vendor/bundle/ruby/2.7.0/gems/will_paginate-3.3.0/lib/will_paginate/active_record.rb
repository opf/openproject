require 'will_paginate/per_page'
require 'will_paginate/page_number'
require 'will_paginate/collection'
require 'active_record'

module WillPaginate
  # = Paginating finders for ActiveRecord models
  # 
  # WillPaginate adds +paginate+, +per_page+ and other methods to
  # ActiveRecord::Base class methods and associations.
  # 
  # In short, paginating finders are equivalent to ActiveRecord finders; the
  # only difference is that we start with "paginate" instead of "find" and
  # that <tt>:page</tt> is required parameter:
  #
  #   @posts = Post.paginate :all, :page => params[:page], :order => 'created_at DESC'
  #
  module ActiveRecord
    # makes a Relation look like WillPaginate::Collection
    module RelationMethods
      include WillPaginate::CollectionMethods

      attr_accessor :current_page
      attr_writer :total_entries

      def per_page(value = nil)
        if value.nil? then limit_value
        else limit(value)
        end
      end

      # TODO: solve with less relation clones and code dups
      def limit(num)
        rel = super
        if rel.current_page
          rel.offset rel.current_page.to_offset(rel.limit_value).to_i
        else
          rel
        end
      end

      # dirty hack to enable `first` after `limit` behavior above
      def first(*args)
        if current_page
          rel = clone
          rel.current_page = nil
          rel.first(*args)
        else
          super
        end
      end

      # fix for Rails 3.0
      def find_last(*args)
        if !loaded? && args.empty? && (offset_value || limit_value)
          @last ||= to_a.last
        else
          super
        end
      end

      def offset(value = nil)
        if value.nil? then offset_value
        else super(value)
        end
      end

      def total_entries
        @total_entries ||= begin
          if loaded? and size < limit_value and (current_page == 1 or size > 0)
            offset_value + size
          else
            @total_entries_queried = true
            result = count
            result = result.size if result.respond_to?(:size) and !result.is_a?(Integer)
            result
          end
        end
      end

      def count(*args)
        if limit_value
          excluded = [:order, :limit, :offset, :reorder]
          excluded << :includes unless eager_loading?
          rel = self.except(*excluded)
          column_name = if rel.select_values.present?
            select = rel.select_values.join(", ")
            select if select !~ /[,*]/
          end || :all
          rel.count(column_name)
        else
          super(*args)
        end
      end

      # workaround for Active Record 3.0
      def size
        if !loaded? and limit_value and group_values.empty?
          [super, limit_value].min
        else
          super
        end
      end

      # overloaded to be pagination-aware
      def empty?
        if !loaded? and offset_value
          total_entries <= offset_value
        else
          super
        end
      end

      def clone
        copy_will_paginate_data super
      end

      # workaround for Active Record 3.0
      def scoped(options = nil)
        copy_will_paginate_data super
      end

      def to_a
        if current_page.nil? then super # workaround for Active Record 3.0
        else
          ::WillPaginate::Collection.create(current_page, limit_value) do |col|
            col.replace super
            col.total_entries ||= total_entries
          end
        end
      end

      private

      def copy_will_paginate_data(other)
        other.current_page = current_page unless other.current_page
        other.total_entries = nil if defined? @total_entries_queried
        other
      end
    end

    module Pagination
      def paginate(options)
        options  = options.dup
        pagenum  = options.fetch(:page) { raise ArgumentError, ":page parameter required" }
        options.delete(:page)
        per_page = options.delete(:per_page) || self.per_page
        total    = options.delete(:total_entries)

        if options.any?
          raise ArgumentError, "unsupported parameters: %p" % options.keys
        end

        rel = limit(per_page.to_i).page(pagenum)
        rel.total_entries = total.to_i          unless total.blank?
        rel
      end

      def page(num)
        rel = if ::ActiveRecord::Relation === self
          self
        elsif !defined?(::ActiveRecord::Scoping) or ::ActiveRecord::Scoping::ClassMethods.method_defined? :with_scope
          # Active Record 3
          scoped
        else
          # Active Record 4
          all
        end

        rel = rel.extending(RelationMethods)
        pagenum = ::WillPaginate::PageNumber(num.nil? ? 1 : num)
        per_page = rel.limit_value || self.per_page
        rel = rel.offset(pagenum.to_offset(per_page).to_i)
        rel = rel.limit(per_page) unless rel.limit_value
        rel.current_page = pagenum
        rel
      end
    end

    module BaseMethods
      # Wraps +find_by_sql+ by simply adding LIMIT and OFFSET to your SQL string
      # based on the params otherwise used by paginating finds: +page+ and
      # +per_page+.
      #
      # Example:
      # 
      #   @developers = Developer.paginate_by_sql ['select * from developers where salary > ?', 80000],
      #                          :page => params[:page], :per_page => 3
      #
      # A query for counting rows will automatically be generated if you don't
      # supply <tt>:total_entries</tt>. If you experience problems with this
      # generated SQL, you might want to perform the count manually in your
      # application.
      # 
      def paginate_by_sql(sql, options)
        pagenum  = options.fetch(:page) { raise ArgumentError, ":page parameter required" } || 1
        per_page = options[:per_page] || self.per_page
        total    = options[:total_entries]

        WillPaginate::Collection.create(pagenum, per_page, total) do |pager|
          query = sanitize_sql(sql.dup)
          original_query = query.dup
          oracle = self.connection.adapter_name =~ /^(oracle|oci$)/i

          # add limit, offset
          if oracle
            query = <<-SQL
              SELECT * FROM (
                SELECT rownum rnum, a.* FROM (#{query}) a
                WHERE rownum <= #{pager.offset + pager.per_page}
              ) WHERE rnum >= #{pager.offset}
            SQL
          elsif (self.connection.adapter_name =~ /^sqlserver/i)
            query << " OFFSET #{pager.offset} ROWS FETCH NEXT #{pager.per_page} ROWS ONLY"
          else
            query << " LIMIT #{pager.per_page} OFFSET #{pager.offset}"
          end

          # perfom the find
          pager.replace find_by_sql(query)

          unless pager.total_entries
            count_query = original_query.sub /\bORDER\s+BY\s+[\w`,\s.]+$/mi, ''
            count_query = "SELECT COUNT(*) FROM (#{count_query})"
            count_query << ' AS count_table' unless oracle
            # perform the count query
            pager.total_entries = count_by_sql(count_query)
          end
        end
      end
    end

    # mix everything into Active Record
    ::ActiveRecord::Base.extend PerPage
    ::ActiveRecord::Base.extend Pagination
    ::ActiveRecord::Base.extend BaseMethods

    klasses = [::ActiveRecord::Relation]
    if defined? ::ActiveRecord::Associations::CollectionProxy
      klasses << ::ActiveRecord::Associations::CollectionProxy
    else
      klasses << ::ActiveRecord::Associations::AssociationCollection
    end

    # support pagination on associations and scopes
    klasses.each { |klass| klass.send(:include, Pagination) }
  end
end
