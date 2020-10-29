require "tilt"
require "uber/inheritable_attr"
require "cell/version"

module Cell
  autoload :Testing,  "cell/testing"

  class TemplateMissingError < RuntimeError
    def initialize(prefixes, view)
      super("Template missing: view: `#{view.to_s}` prefixes: #{prefixes.inspect}")
    end
  end # Error
end

require "cell/caching"
require "cell/prefixes"
require "cell/layout"
require "cell/templates"
require "cell/abstract"
require "cell/util"
require "cell/view_model"
require "cell/concept"
require "cell/escaped"
require "cell/builder"
require "cell/collection"
