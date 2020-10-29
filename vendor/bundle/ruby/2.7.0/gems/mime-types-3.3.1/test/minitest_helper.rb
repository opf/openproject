# frozen_string_literal: true

require 'mime/type'
require 'fileutils'

gem 'minitest'
require 'fivemat/minitest/autorun'
require 'minitest/focus'
require 'minitest/rg'
require 'minitest-bonus-assertions'
require 'minitest/hooks'

ENV['RUBY_MIME_TYPES_LAZY_LOAD'] = 'yes'
