fail "upgrade ruby version, ruby < 1.8.7 suffers from Hash#hash bug" if {:a => 10}.hash != {:a => 10}.hash
#require "hwia_rails"

require 'big_decimal_patch'
require 'to_date_patch'

# Defines the minimum number of cells for a 'big' report
# Big reports may be handled differently in the UI - i.e. ask the user
# if he's really sure to execute such a heavy report
Widget::Table::Progressbar.const_set 'THRESHHOLD', 500