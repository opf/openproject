require "cells/rails/version"
require "cells"

require "cell/caching/notification"
require "cell/rails"
require "cell/railtie"
require "cell/rails/testing"

module Cell
  autoload :Translation, "cell/translation"
  autoload :TestCase, "cell/test_case"
end
