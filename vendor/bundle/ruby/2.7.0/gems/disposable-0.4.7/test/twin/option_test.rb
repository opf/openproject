# require "test_helper"

# class TwinOptionTest < Minitest::Spec
#   module Model
#     Song  = Struct.new(:id, :title, :album)
#   end

#   class Song < Disposable::Twin
#     property :id
#     property :title

#     def self.option(name, options={})
#       property(name, options.merge(virtual: true))
#     end

#     option :preview?
#     option :current_user
#   end

#   let (:song) { Model::Song.new(1, "Broken") }
#   let (:twin) { Song.new(song, :preview? => false) }


#   # properties are read from model.
#   it { twin.id.must_equal 1 }
#   it { twin.title.must_equal "Broken" }

#   # option is not delegated to model.
#   it { twin.preview?.must_equal false }
#   # not passing option means zero.
#   it { twin.current_user.must_be_nil }

#   describe "passing all options" do
#     let (:twin) { Song.new(song, :preview? => false, current_user: Object) }

#     it { twin.preview?.must_equal false }
#     it { twin.current_user.must_equal Object }
#   end
# end
