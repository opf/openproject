require "pp"
require 'minitest/autorun'

ENV['RAILS_ENV'] = 'test'


require "cells"
require_relative 'dummy/config/environment'

require "cell/erb"
