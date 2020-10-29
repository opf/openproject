# require 'test_helper'
# require 'cell/twin'

# class TwinTest < MiniTest::Spec
#   class SongCell < Cell::ViewModel
#     class Twin < Disposable::Twin
#       property :title
#       option :online?
#     end

#     include Cell::Twin
#     twin Twin

#     def show
#       "#{title} is #{online?}"
#     end

#     def title
#       super.downcase
#     end
#   end

#   let (:model) { OpenStruct.new(title: "Kenny") }

#   it { SongCell.new( model, :online? => true).call.must_equal "kenny is true" }
# end
