# frozen_string_literal: true

# The recommended way to extend Prawn's functionality is to include the
# <code>Prawn::View</code> mixin in your own class, which will make all
# <code>Prawn::Document</code> methods available to your custom objects.
#
# This approach is preferred over inheriting from
# <code>Prawn::Document</code>, as your state will be kept completely separate
# from <code>Prawn::Document</code>'s, thus avoiding accidental method
# collisions.
#
# Note that <code>Prawn::View</code> lazily instantiates a
# <code>Prawn::Document</code> with default initialization settings, such as
# page size, layout, margins, etc.
#
# By defining your own <code>document</code> method, as shown in the example,
# you will be able to override those settings and initialize a
# <code>Prawn::Document</code> to your heart's content. This method will be
# called repeatedly by <code>Prawn::View</code>, so be sure to memoize the
# object by assigning it to an instance variable via the <code>||=</code>
# operator.

require_relative '../example_helper'

class Greeter
  include Prawn::View

  def initialize(name)
    @name = name
  end

  def say_hello
    text "Hello, #{@name}!"
  end

  def say_goodbye
    font('Courier') do
      text "Goodbye, #{@name}!"
    end
  end
end

greeter = Greeter.new('Gregory')

greeter.say_hello
greeter.say_goodbye

greeter.save_as('greetings.pdf')
