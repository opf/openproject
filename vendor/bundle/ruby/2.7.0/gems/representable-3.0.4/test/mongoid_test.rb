# require 'test_helper'
# require 'mongoid'
# require 'mongoid/document'

# class MongoidTest < MiniTest::Spec
#   describe "Mongoid compatibility" do
#     it "allows #to_json" do
#       class Profile
#         include Mongoid::Document
#         field :name
#       end

#       class Dude
#         include Mongoid::Document
#         embeds_one :profile, :class_name => "MongoidTest::Profile"
#       end

#       module ProfileRepresenter
#        include Representable::JSON

#        property :name
#       end

#       dude = Dude.new
#       dude.profile = Profile.new
#       dude.profile.name = "Kofi"

#       assert_equal "{\"name\":\"Kofi\"}", dude.profile.extend(ProfileRepresenter).to_json
#     end
#   end
# end
