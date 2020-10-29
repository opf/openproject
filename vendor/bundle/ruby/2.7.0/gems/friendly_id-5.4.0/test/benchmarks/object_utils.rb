require File.expand_path("../../helper", __FILE__)

# This benchmark compares the timings of the friendly_id? and unfriendly_id? on various objects
#
# integer friendly_id?            6.370000   0.000000   6.370000 (  6.380925)
# integer unfriendly_id?          6.640000   0.010000   6.650000 (  6.646057)
# AR::Base friendly_id?           2.340000   0.000000   2.340000 (  2.340743)
# AR::Base unfriendly_id?         2.560000   0.000000   2.560000 (  2.560039)
# hash friendly_id?               5.090000   0.010000   5.100000 (  5.097662)
# hash unfriendly_id?             5.430000   0.000000   5.430000 (  5.437160)
# nil friendly_id?                5.610000   0.010000   5.620000 (  5.611487)
# nil unfriendly_id?              5.870000   0.000000   5.870000 (  5.880484)
# numeric string friendly_id?     9.270000   0.030000   9.300000 (  9.308452)
# numeric string unfriendly_id?   9.190000   0.040000   9.230000 (  9.252890)
# test_string friendly_id?        8.380000   0.010000   8.390000 (  8.411762)
# test_string unfriendly_id?      8.450000   0.010000   8.460000 (  8.463662)

# From the ObjectUtils docs...
#     123.friendly_id?                  #=> false
#     :id.friendly_id?                  #=> false
#     {:name => 'joe'}.friendly_id?     #=> false
#     ['name = ?', 'joe'].friendly_id?  #=> false
#     nil.friendly_id?                  #=> false
#     "123".friendly_id?                #=> nil
#     "abc123".friendly_id?             #=> true

Book = Class.new ActiveRecord::Base

test_integer = 123
test_active_record_object = Book.new
test_hash = {:name=>'joe'}
test_nil = nil
test_numeric_string = "123"
test_string = "abc123"

N = 5_000_000

Benchmark.bmbm do |x|
  x.report('integer friendly_id?') { N.times {test_integer.friendly_id?} }
  x.report('integer unfriendly_id?') { N.times {test_integer.unfriendly_id?} }

  x.report('AR::Base friendly_id?') { N.times {test_active_record_object.friendly_id?} }
  x.report('AR::Base unfriendly_id?') { N.times {test_active_record_object.unfriendly_id?} }

  x.report('hash friendly_id?') { N.times {test_hash.friendly_id?} }
  x.report('hash unfriendly_id?') { N.times {test_hash.unfriendly_id?} }

  x.report('nil friendly_id?') { N.times {test_nil.friendly_id?} }
  x.report('nil unfriendly_id?') { N.times {test_nil.unfriendly_id?} }

  x.report('numeric string friendly_id?') { N.times {test_numeric_string.friendly_id?} }
  x.report('numeric string unfriendly_id?') { N.times {test_numeric_string.unfriendly_id?} }

  x.report('test_string friendly_id?') { N.times {test_string.friendly_id?} }
  x.report('test_string unfriendly_id?') { N.times {test_string.unfriendly_id?} }
end
