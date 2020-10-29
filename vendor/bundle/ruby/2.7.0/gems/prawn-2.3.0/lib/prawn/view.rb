# frozen_string_literal: true

# prawn/view.rb : Implements a mixin for Prawn's DSL
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  # This mixin allows you to create modular Prawn code without the
  # need to create subclasses of Prawn::Document.
  #
  #     class Greeter
  #       include Prawn::View
  #
  #       # Optional override: allows you to set document options or even use
  #       # a custom document class
  #       def document
  #         @document ||= Prawn::Document.new(page_size: 'A4')
  #       end
  #
  #       def initialize(name)
  #         @name = name
  #       end
  #
  #       def say_hello
  #         text "Hello, #{@name}!"
  #       end
  #
  #       def say_goodbye
  #         font("Courier") do
  #           text "Goodbye, #{@name}!"
  #         end
  #       end
  #    end
  #
  #    greeter = Greeter.new("Gregory")
  #
  #    greeter.say_hello
  #    greeter.say_goodbye
  #
  #    greeter.save_as("greetings.pdf")
  #
  # The short story about why you should use this mixin rather than
  # creating subclasses of +Prawn::Document+ is that it helps
  # prevent accidental conflicts between your code and Prawn's
  # code.
  #
  # Here's the slightly longer story...
  #
  # By using composition rather than inheritance under the hood, this
  # mixin allows you to keep your state separate from +Prawn::Document+'s
  # state, and also will prevent unexpected method name collisions due
  # to late binding effects.
  #
  # This mixin is mostly meant for extending Prawn's functionality
  # with your own additions, but you can also use it to replace or
  # wrap existing Prawn methods. Calling +super+ will still work
  # as expected, and alternatively you can explictly call
  # +document.some_method+ to delegate to Prawn where needed.
  module View
    # @group Experimental API

    # Lazily instantiates a +Prawn::Document+ object.
    #
    # You can also redefine this method in your own classes to use
    # a custom document class.
    def document
      @document ||= Prawn::Document.new
    end

    # Delegates all unhandled calls to object returned by +document+ method.
    # (which is an instance of Prawn::Document by default)
    def method_missing(method_name, *arguments, &block)
      return super unless document.respond_to?(method_name)

      document.send(method_name, *arguments, &block)
    end

    def respond_to_missing?(method_name, _include_all = false)
      document.respond_to?(method_name)
    end

    # Syntactic sugar that uses +instance_eval+ under the hood to provide
    # a block-based DSL.
    #
    #    greeter.update do
    #      say_hello
    #      say_goodbye
    #    end
    #
    def update(&block)
      instance_eval(&block)
    end

    # Syntatic sugar that calls +document.render_file+ under the hood.
    #
    #    greeter.save_as("greetings.pdf")
    def save_as(filename)
      document.render_file(filename)
    end
  end
end
