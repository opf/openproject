# = Term::ANSIColor - ANSI escape sequences in Ruby
#
# == Description
#
# This library can be used to color/uncolor strings using ANSI escape sequences.
#
# == Author
#
# Florian Frank mailto:flori@ping.de
#
# == License
#
# This is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License Version 2 as published by the Free
# Software Foundation: www.gnu.org/copyleft/gpl.html
#
# == Download
#
# The latest version of this library can be downloaded at
#
# * http://rubyforge.org/frs?group_id=391
#
# The homepage of this library is located at
#
# * http://term-ansicolor.rubyforge.org
#
# == Examples
# 
# The file examples/example.rb in the source/gem-distribution shows how
# this library can be used:
#  require 'term/ansicolor'
#  
#  # Use this trick to work around namespace cluttering that
#  # happens if you just include Term::ANSIColor:
#  
#  class Color
#    class << self
#      include Term::ANSIColor
#    end
#  end
#  
#  print Color.red, Color.bold, "No Namespace cluttering:", Color.clear, "\n"
#  print Color.green + "green" + Color.clear, "\n"
#  print Color.on_red(Color.green("green")), "\n"
#  print Color.yellow { Color.on_black { "yellow on_black" } }, "\n\n"
#  
#  # Or shortcut Term::ANSIColor by assignment:
#  c = Term::ANSIColor
#  
#  print c.red, c.bold, "No Namespace cluttering (alternative):", c.clear, "\n"
#  print c.green + "green" + c.clear, "\n"
#  print c.on_red(c.green("green")), "\n"
#  print c.yellow { c.on_black { "yellow on_black" } }, "\n\n"
#  
#  # Anyway, I don't define any of Term::ANSIColor's methods in this example
#  # and I want to keep it short:
#  include Term::ANSIColor
#  
#  print red, bold, "Usage as constants:", reset, "\n"
#  print clear, "clear", reset, reset, "reset", reset,
#    bold, "bold", reset, dark, "dark", reset,
#    underscore, "underscore", reset, blink, "blink", reset,
#    negative, "negative", reset, concealed, "concealed", reset, "|\n",
#    black, "black", reset, red, "red", reset, green, "green", reset,
#    yellow, "yellow", reset, blue, "blue", reset, magenta, "magenta", reset,
#    cyan, "cyan", reset, white, "white", reset, "|\n",
#    on_black, "on_black", reset, on_red, "on_red", reset,
#    on_green, "on_green", reset, on_yellow, "on_yellow", reset,
#    on_blue, "on_blue", reset, on_magenta, "on_magenta", reset,
#    on_cyan, "on_cyan", reset, on_white, "on_white", reset, "|\n\n"
#  
#  print red, bold, "Usage as unary argument methods:", reset, "\n"
#  print clear("clear"), reset("reset"), bold("bold"), dark("dark"),
#    underscore("underscore"), blink("blink"), negative("negative"),
#    concealed("concealed"), "|\n",
#    black("black"), red("red"), green("green"), yellow("yellow"),
#    blue("blue"), magenta("magenta"), cyan("cyan"), white("white"), "|\n",
#    on_black("on_black"), on_red("on_red"), on_green("on_green"),#
#    on_yellow("on_yellow"), on_blue("on_blue"), on_magenta("on_magenta"),
#    on_cyan("on_cyan"), on_white("on_white"), "|\n\n"
#  
#  print red { bold { "Usage as block forms:" } }, "\n"
#  print clear { "clear" }, reset { "reset" }, bold { "bold" },
#    dark { "dark" }, underscore { "underscore" }, blink { "blink" },
#    negative { "negative" }, concealed { "concealed" }, "|\n",
#    black { "black" }, red { "red" }, green { "green" },
#    yellow { "yellow" }, blue { "blue" }, magenta { "magenta" },
#    cyan { "cyan" }, white { "white" }, "|\n",
#    on_black { "on_black" }, on_red { "on_red" }, on_green { "on_green" },
#    on_yellow { "on_yellow" }, on_blue { "on_blue" },
#    on_magenta { "on_magenta" }, on_cyan { "on_cyan" },
#    on_white { "on_white" }, "|\n\n"
#  
#  # Usage as Mixin into String or its Subclasses
#  class String
#    include Term::ANSIColor
#  end
#  
#  print "Usage as String Mixins:".red.bold, "\n"
#  print "clear".clear, "reset".reset, "bold".bold, "dark".dark,
#    "underscore".underscore, "blink".blink, "negative".negative,
#    "concealed".concealed, "|\n",
#    "black".black, "red".red, "green".green, "yellow".yellow,
#    "blue".blue, "magenta".magenta, "cyan".cyan, "white".white, "|\n",
#    "on_black".on_black, "on_red".on_red, "on_green".on_green,
#    "on_yellow".on_yellow, "on_blue".on_blue, "on_magenta".on_magenta,
#    "on_cyan".on_cyan, "on_white".on_white, "|\n\n"
#  
#  symbols = Term::ANSIColor::attributes
#  print red { bold { "All supported attributes = " } },
#    blue { symbols.inspect }, "\n\n"
#  
#  print "Send symbols to strings:".send(:red).send(:bold), "\n"
#  print symbols[12, 8].map { |c| c.to_s.send(c) }, "\n\n"
#  
#  print red { bold { "Make strings monochromatic again:" } }, "\n"
#  print [ "red".red, "not red anymore".red.uncolored,
#    uncolored { "not red anymore".red }, uncolored("not red anymore".red)
#      ].map { |x| x + "\n" }
module Term
  # The ANSIColor module can be used for namespacing and mixed into your own
  # classes.
  module ANSIColor
    # :stopdoc:
    ATTRIBUTES = [
      [ :clear        ,   0 ], 
      [ :reset        ,   0 ],     # synonym for :clear
      [ :bold         ,   1 ], 
      [ :dark         ,   2 ], 
      [ :italic       ,   3 ],     # not widely implemented
      [ :underline    ,   4 ], 
      [ :underscore   ,   4 ],     # synonym for :underline
      [ :blink        ,   5 ], 
      [ :rapid_blink  ,   6 ],     # not widely implemented
      [ :negative     ,   7 ],     # no reverse because of String#reverse
      [ :concealed    ,   8 ], 
      [ :strikethrough,   9 ],     # not widely implemented
      [ :black        ,  30 ], 
      [ :red          ,  31 ], 
      [ :green        ,  32 ], 
      [ :yellow       ,  33 ], 
      [ :blue         ,  34 ], 
      [ :magenta      ,  35 ], 
      [ :cyan         ,  36 ], 
      [ :white        ,  37 ], 
      [ :on_black     ,  40 ], 
      [ :on_red       ,  41 ], 
      [ :on_green     ,  42 ], 
      [ :on_yellow    ,  43 ], 
      [ :on_blue      ,  44 ], 
      [ :on_magenta   ,  45 ], 
      [ :on_cyan      ,  46 ], 
      [ :on_white     ,  47 ], 
    ]

    ATTRIBUTE_NAMES = ATTRIBUTES.transpose.first
    # :startdoc:

    # Returns true, if the coloring function of this module
    # is switched on, false otherwise.
    def self.coloring?
      @coloring
    end

    # Turns the coloring on or off globally, so you can easily do
    # this for example:
    #  Term::ANSIColor::coloring = STDOUT.isatty
    def self.coloring=(val)
      @coloring = val
    end
    self.coloring = true

    ATTRIBUTES.each do |c, v|
      eval %Q{
          def #{c}(string = nil)
            result = ''
            result << "\e[#{v}m" if Term::ANSIColor.coloring?
            if block_given?
              result << yield
            elsif string
              result << string
            elsif respond_to?(:to_str)
              result << self
            else
              return result #only switch on
            end
            result << "\e[0m" if Term::ANSIColor.coloring?
            result
          end
      }
    end

    # Regular expression that is used to scan for ANSI-sequences while
    # uncoloring strings.
    COLORED_REGEXP = /\e\[([34][0-7]|[0-9])m/

    # Returns an uncolored version of the string, that is all
    # ANSI-sequences are stripped from the string.
    def uncolored(string = nil) # :yields:
      if block_given?
        yield.gsub(COLORED_REGEXP, '')
      elsif string
        string.gsub(COLORED_REGEXP, '')
      elsif respond_to?(:to_str)
        gsub(COLORED_REGEXP, '')
      else
        ''
      end
    end

    module_function

    # Returns an array of all Term::ANSIColor attributes as symbols.
    def attributes
      ATTRIBUTE_NAMES
    end
    extend self
  end
end
    # vim: set et sw=2 ts=2:
