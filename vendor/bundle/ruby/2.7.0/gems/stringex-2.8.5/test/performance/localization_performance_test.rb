require "test_helper"
require 'stringex'
require 'i18n'
require 'benchmark'

class LocalizationPerformanceTest < Test::Unit::TestCase
  def setup
    I18n.locale = :en
    Stringex::Localization.reset!
  end

  def test_i18n_performance
    Stringex::Localization.backend = :internal
    internal_time = Benchmark.realtime { 100.times{ "alskdjfal".to_url } }

    Stringex::Localization.backend = :i18n
    i18n_time = Benchmark.realtime { 100.times{ "alskdjfal".to_url } }

    percentage_difference = ((i18n_time - internal_time) / internal_time) * 100
    allowed_difference = 25

    assert percentage_difference <= allowed_difference, "The I18n backend is #{percentage_difference.to_i} percent slower than the internal backend. The allowed difference is #{allowed_difference} percent."
  end
end
