# frozen_string_literal: true

module Prawn
  class Document
    # @group Stable API

    # Lazily instantiates a Prawn::Outline object for document. This is used as
    # point of entry to methods to build the outline tree for a document's table
    # of contents.
    def outline
      @outline ||= Outline.new(self)
    end
  end

  # The Outline class organizes the outline tree items for the document.
  # Note that the prev and parent instance variables are adjusted while
  # navigating through the nested blocks. These variables along with the
  # presence or absense of blocks are the primary means by which the relations
  # for the various OutlineItems and the OutlineRoot are set. Unfortunately, the
  # best way to understand how this works is to follow the method calls through
  # a real example.
  #
  # Some ideas for the organization of this class were gleaned from name_tree.
  # In particular the way in which the OutlineItems are finally rendered into
  # document objects in PdfObject through a hash.
  #
  class Outline
    # @private
    attr_accessor :parent, :prev, :document, :items

    def initialize(document)
      @document = document
      @parent = root
      @prev = nil
      @items = {}
    end

    # @group Stable API

    # Returns the current page number of the document
    def page_number
      @document.page_number
    end

    # Defines/Updates an outline for the document.
    # The outline is an optional nested index that appears on the side of a PDF
    # document usually with direct links to pages. The outline DSL is defined by
    # nested blocks involving two methods: section and page; see the
    # documentation on those methods for their arguments and options. Note that
    # one can also use outline#update to add more sections to the end of the
    # outline tree using the same syntax and scope.
    #
    # The syntax is best illustrated with an example:
    #
    # Prawn::Document.generate(outlined_document.pdf) do
    #   text "Page 1. This is the first Chapter. "
    #   start_new_page
    #   text "Page 2. More in the first Chapter. "
    #   start_new_page
    #   outline.define do
    #     section 'Chapter 1', :destination => 1, :closed => true do
    #       page :destination => 1, :title => 'Page 1'
    #       page :destination => 2, :title => 'Page 2'
    #     end
    #   end
    #   start_new_page do
    #   outline.update do
    #     section 'Chapter 2', :destination =>  2, do
    #       page :destination => 3, :title => 'Page 3'
    #     end
    #   end
    # end
    #
    def define(&block)
      instance_eval(&block) if block
    end

    alias update define

    # Inserts an outline section to the outline tree (see outline#define).
    # Although you will probably choose to exclusively use outline#define so
    # that your outline tree is contained and easy to manage, this method gives
    # you the option to insert sections to the outline tree at any point during
    # document generation. This method allows you to add a child subsection to
    # any other item at any level in the outline tree.  Currently the only way
    # to locate the place of entry is with the title for the item. If your title
    # names are not unique consider using define_outline.
    # The method takes the following arguments:
    #   title: a string that must match an outline title to add
    #     the subsection to
    #   position: either :first or :last (the default) where the subsection will
    #     be placed relative to other child elements. If you need to position
    #     your subsection in between other elements then consider using
    #     #insert_section_after
    #   block: uses the same DSL syntax as outline#define, for example:
    #
    # Consider using this method inside of outline.update if you want to have
    # the outline object to be scoped as self (see #insert_section_after
    # example).
    #
    #   go_to_page 2
    #   start_new_page
    #   text "Inserted Page"
    #   outline.add_subsection_to :title => 'Page 2', :first do
    #     outline.page :destination => page_number, :title => "Inserted Page"
    #   end
    #
    def add_subsection_to(title, position = :last, &block)
      @parent = items[title]
      unless @parent
        raise Prawn::Errors::UnknownOutlineTitle,
          "\n No outline item with title: '#{title}' exists in the outline tree"
      end
      @prev = position == :first ? nil : @parent.data.last
      nxt = position == :first ? @parent.data.first : nil
      insert_section(nxt, &block)
    end

    # Inserts an outline section to the outline tree (see outline#define).
    # Although you will probably choose to exclusively use outline#define so
    # that your outline tree is contained and easy to manage, this method gives
    # you the option to insert sections to the outline tree at any point during
    # document generation. Unlike outline.add_section, this method allows you to
    # enter a section after any other item at any level in the outline tree.
    # Currently the only way to locate the place of entry is with the title for
    # the item. If your title names are not unique consider using
    # define_outline.
    # The method takes the following arguments:
    #   title: the title of other section or page to insert new section after
    #   block: uses the same DSL syntax as outline#define, for example:
    #
    #   go_to_page 2
    #   start_new_page
    #   text "Inserted Page"
    #   update_outline do
    #     insert_section_after :title => 'Page 2' do
    #       page :destination => page_number, :title => "Inserted Page"
    #     end
    #   end
    #
    def insert_section_after(title, &block)
      @prev = items[title]
      unless @prev
        raise Prawn::Errors::UnknownOutlineTitle,
          "\n No outline item with title: '#{title}' exists in the outline tree"
      end
      @parent = @prev.data.parent
      nxt = @prev.data.next
      insert_section(nxt, &block)
    end

    # See outline#define above for documentation on how this is used in that
    # context
    #
    # Adds an outine section to the outline tree.
    # Although you will probably choose to exclusively use outline#define so
    # that your outline tree is contained and easy to manage, this method gives
    # you the option to add sections to the outline tree at any point during
    # document generation. When not being called from within another #section
    # block the section will be added at the top level after the other root
    # elements of the outline.  For more flexible placement try using
    # outline#insert_section_after and/or outline#add_subsection_to
    #
    # Takes the following arguments:
    #   title: the outline text that appears for the section.
    #   options: destination - optional integer defining the page number for
    #                 a destination link to the top of the page (using a :FIT
    #                 destination).
    #                 - or an array with a custom destination (see the #dest_*
    #                 methods of the PDF::Destination module)
    #            closed - whether the section should show its nested outline
    #                     elements.
    #                   - defaults to false.
    #            block: more nested subsections and/or page blocks
    #
    # example usage:
    #
    #   outline.section 'Added Section', :destination => 3 do
    #     outline.page :destionation => 3, :title => 'Page 3'
    #   end
    def section(title, options = {}, &block)
      add_outline_item(title, options, &block)
    end

    # See Outline#define above for more documentation on how it is used in that
    # context
    #
    # Adds a page to the outline.
    # Although you will probably choose to exclusively use outline#define so
    # that your outline tree is contained and easy to manage, this method also
    # gives you the option to add pages to the root of outline tree at any point
    # during document generation. Note that the page will be added at the top
    # level after the other root outline elements. For more flexible placement
    # try using outline#insert_section_after and/or outline#add_subsection_to.
    #
    # Takes the following arguments:
    #   options:
    #     title - REQUIRED. The outline text that appears for the page.
    #     destination - optional integer defining the page number for
    #             a destination link to the top of the page (using a :FIT
    #             destination).
    #             or an array with a custom destination (see the dest_* methods
    #             of the PDF::Destination module)
    #     closed - whether the section should show its nested outline elements.
    #            - defaults to false.
    # example usage:
    #
    #   outline.page :title => "Very Last Page"
    #
    # Note: this method is almost identical to section except that it does not
    # accept a block thereby defining the outline item as a leaf on the outline
    # tree structure.
    def page(options = {})
      if options[:title]
        title = options[:title]
      else
        raise Prawn::Errors::RequiredOption,
          "\nTitle is a required option for page"
      end
      add_outline_item(title, options)
    end

    private

    # The Outline dictionary (12.3.3) for this document.  It is
    # lazily initialized, so that documents that do not have an outline
    # do not incur the additional overhead.
    def root
      document.state.store.root.data[:Outlines] ||=
        document.ref!(PDF::Core::OutlineRoot.new)
    end

    def add_outline_item(title, options, &block)
      outline_item = create_outline_item(title, options)
      establish_relations(outline_item)
      increase_count
      set_variables_for_block(outline_item, block)
      yield if block
      reset_parent(outline_item)
    end

    def create_outline_item(title, options)
      outline_item = PDF::Core::OutlineItem.new(title, parent, options)

      case options[:destination]
      when Integer
        page_index = options[:destination] - 1
        outline_item.dest = [document.state.pages[page_index].dictionary, :Fit]
      when Array
        outline_item.dest = options[:destination]
      end

      outline_item.prev = prev if @prev
      items[title] = document.ref!(outline_item)
    end

    def establish_relations(outline_item)
      prev.data.next = outline_item if prev
      parent.data.first = outline_item unless prev
      parent.data.last = outline_item
    end

    def increase_count
      counting_parent = parent
      while counting_parent
        counting_parent.data.count += 1
        counting_parent = if counting_parent == root
                            nil
                          else
                            counting_parent.data.parent
                          end
      end
    end

    def set_variables_for_block(outline_item, block)
      self.prev = block ? nil : outline_item
      self.parent = outline_item if block
    end

    def reset_parent(outline_item)
      if parent == outline_item
        self.prev = outline_item
        self.parent = outline_item.data.parent
      end
    end

    def insert_section(nxt, &block)
      last = @parent.data.last
      if block
        yield
      end
      adjust_relations(nxt, last)
      reset_root_positioning
    end

    def adjust_relations(nxt, last)
      if nxt
        nxt.data.prev = @prev
        @prev.data.next = nxt
        @parent.data.last = last
      end
    end

    def reset_root_positioning
      @parent = root
      @prev = root.data.last
    end
  end
end
