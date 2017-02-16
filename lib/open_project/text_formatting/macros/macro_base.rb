#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module OpenProject::TextFormatting::Macros
  #
  # The class MacroBase models a base for user defined macros that can be referenced from within
  # markup, e.g. wiki markup, and which then will be executed during rendering of that markup.
  #
  # All user defined macros must inherit from this.
  #
  # Macros must declare a descriptor as follows
  #
  # <pre>
  # class MyMacro < OpenProject::MacroBase
  #   descriptor {
  #     prefix        :my_prefix    # a valid XML NS prefix, e.g. :my_prefix or 'my-prefix'
  #     id            :my_id        # a valid XML Element Name, e.g. :my_id or 'my-id'
  #     desc          'desc'        # localized text or a simple string or <<-DESC ... DESC
  #     param {                     # optional parameters
  #       name        :my_param     # a valid XML attribute name, e.g. :my_param or 'my-param' or 'my:param'
  #     }
  #     # ...
  #   }
  #
  #   # the rest of your macro realization ...
  # end
  # </pre>
  #
  # See OpenProject::TextFormatting::Macros::MacroDescriptor for more information
  #
  class MacroBase
    require 'open_project/text_formatting/macros/internal/macro_registry'
    require 'open_project/text_formatting/macros/internal/macros_state'
    require 'open_project/text_formatting/macros/internal/macro_descriptor_builder'

    include OpenProject::TextFormatting
    include Redmine::I18n

    attr_reader :state, :view

    #
    # Content provided as a parameter to macros that declare `MacroDescriptor#with_content`,
    # will be made available in the args passed on execution by this key.
    #
    OPF_CONTENT = :opf_content unless const_defined?(:OPF_CONTENT)

    #
    # Make available the descriptor specification DSL
    #
    def self.inherited(child_class)
      super

      # By convention, base classes are considered abstract and will not be able to register
      # themselves with the registry nor will they sport the DSL for declaring descriptors
      unless child_class.name.end_with?('Base')
        #
        # Allow macros to declare their descriptor using a simple DSL.
        #
        child_class.define_singleton_method(:descriptor) do |&block|
          desc = OpenProject::TextFormatting::Macros::Internal::MacroDescriptorBuilder.build(&block)

          # replace descriptor method and return the descriptor instead
          self.define_singleton_method(:descriptor) do
            desc
          end
        end

        #
        # Allow macros to register themselves with the registry using `register!`.
        # `register!` must be used inside the class declaration just before the `end`.
        #
        child_class.define_singleton_method(:register!) do
          if child_class.instance_variable_get(:@registered).nil?
            child_class.instance_variable_set :@registered, true
            OpenProject::TextFormatting::Macros::Internal::MacroRegistry
              .instance.register child_class
          end
        end
      end
    end

    def initialize(view)
      @view = view

      # prepare or retrieve the state if this is a stateful macro
      if self.class.respond_to?(:descriptor) && self.class.descriptor.stateful?
        @state = OpenProject::TextFormatting::Macros::Internal::MacrosState
                   .instance.get_or_create(self.class.descriptor)
      end
    end

    #
    # Executes the macro.
    #
    # Inside your macro logic, you have full access to the view state. This means that you
    # can make use of the available helpers by just calling them, e.g. `view.<helper>(...)`.
    #
    # As of Rails >=5.0.x all helpers will be made available in the view. If you require
    # additional helpers, just put them into your macro plugin's app/helpers folder.
    #
    # The returned text, or markup, or document fragment will be included in the resulting
    # document. In case of an error, further processing will be passed on to #handle_error
    # by `OpenProject::TextProcessing::Macros::Transformer::MacroTransformer`.
    #
    # @return text or markup or Nokogiri::XML fragment
    #
    def execute(args, **_options)
      throw NotImplementedError.new
    end

    #
    # Handler for macro errors.
    #
    # The user must not call this directly, instead, any unhandled exceptions that occurred during
    # execute will be caught by the MacroTransformer. The MacroTransformer then will call this in
    # order to prepare a rendering of the error.
    #
    # The purpose of this is to provide both the user/administrator and the developer with enough
    # information to either handle the error by themselves, e.g. cyclic inclusion, or to file bug
    # reports with the information provided by this.
    #
    # Side Notes:
    #
    # The result of this rendering the error information is that it will be included directly into
    # the resulting document, leaving open many possibilities, such as integration into AngularJS
    # and so on.
    #
    def handle_error(descriptor)
      unless view.respond_to?(:render)
        raise descriptor.error
      end
      view.render partial: 'wiki/macros/error', locals: { descriptor: descriptor }

      # # TODO:coy:refactor to partial/macro_helper
      # result = Nokogiri::HTML.fragment '<div class="wiki-macro-error"/>'
      # div = result.children.first
      # desc = result.document.create_element 'div'
      # em = result.document.create_element 'em'
      # desc.add_child em
      # em.add_child result.document.create_text_node(
      #   "Error Executing Macro #{descriptor.qname}"
      # )
      # div.add_child desc
      # code = result.document.create_element 'code'
      # code.add_child result.document.create_text_node(descriptor.error.to_s)
      # unless descriptor.error.cause.nil?
      #   code.add_child result.document.create_text_node(' Cause: ')
      #   code.add_child result.document.create_text_node(descriptor.error.cause.to_s)
      #   # TODO:coy:render backtrace
      #   code.add_child result.document.create_text_node(descriptor.error.backtrace[0..30].join('<br/>'))
      # end
      # div.add_child code
      # result
    end

    #
    # Gets the current request from the view or nil if no such request is defined.
    #
    def request
      view.request
    rescue
      nil
    end

    def to_html(*args)
      # we need to persist macro state here during for example recursive inclusion, as
      # otherwise the change in state will not be visible to new stateful instances of
      # for example the IncludeMacro
      if self.class.respond_to?(:descriptor) && self.class.descriptor.stateful?
        OpenProject::TextFormatting::Macros::Internal::MacrosState
          .instance.set_state self.class.descriptor, state
      end
      format_text *args
    end
  end
end
