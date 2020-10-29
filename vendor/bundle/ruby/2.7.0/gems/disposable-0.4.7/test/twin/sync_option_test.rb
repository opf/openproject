# require 'test_helper'
# require "disposable/twin/changed"

# class SyncOptionTest < MiniTest::Spec
#   module Model
#     Song  = Struct.new(:title, :composer)
#     Album = Struct.new(:id, :name, :songs, :artist)
#     Artist = Struct.new(:name, :hidden_taste)
#   end


#   module Twin
#     class Album < Disposable::Twin
#       feature Setup
#       feature Sync
#       # feature Changed

#       property :id,   sync: lambda { |value, options| nil }
#       property :name, sync: lambda { |value, options| value == "Run For Cover" ? model.name= "processed+#{value}" : model.name= "#{value}+unprocessed" } # assign if album name is "Run For Cover".

#       collection :songs ,
#          sync: lambda { |value, options|  } do # FIXME: this is called before the songs items where synced?
#         property :title, sync: lambda { |value, options| value == "Empty Rooms" ? model.title= "++#{value}" : nil }
#       end

#       property :artist, sync: lambda { |twin, options| twin.model.hidden_taste = "Ska" } do
#         property :name
#       end
#     end
#   end



#   # sync does NOT call setter.
#   describe ":sync allows you conditionals and is run in twin context" do
#     let (:album) { Model::Album.new(1, "Corridors Of Power", [song, song_with_composer], artist) }
#     let (:song) { Model::Song.new() }
#     let (:song_with_composer) { Model::Song.new("American Jesus", composer) }
#     let (:composer) { Model::Artist.new(nil) }
#     let (:artist) { Model::Artist.new("Bad Religion") }

#     let (:twin) { Twin::Album.new(album) }

#     it do
#       album.instance_exec { def id=(*);    raise "don't call me!"; end }
#       song.instance_exec  { def title=(*); raise "don't call me!"; end }

#       # triggers :sync.
#       twin.name = "Run For Cover"

#       twin.songs[1].title = "Empty Rooms" # song_with_composer. this will trigger the #title= writer.
#       twin.artist.name = "Gary Moore"

#       twin.sync # name is still "Corridors Of Power"

#       # Album#id :sync was called, nothing happened.
#       album.id.must_equal 1
#       # Album#name :sync was called, first case.
#       album.name.must_equal "processed+Run For Cover"
#       # Song#title :sync called but returns nil.
#       song.title.must_be_nil
#       # Song#title :sync called and processed, first case.
#       song_with_composer.title.must_equal "++Empty Rooms"

#       # Artist#name :sync was called.
#       artist.name.must_equal "Gary Moore"
#       # Album#artist :sync was called.
#       artist.hidden_taste.must_equal "Ska"
#     end

#     # trigger second case of Album#name to make sure conditionals work.
#     it do
#       twin.name = "This is not: Run For Cover" # triggers :sync, second case.
#       twin.sync
#       album.name.must_equal "This is not: Run For Cover+unprocessed"
#     end
#   end
# end


# class SyncWithDynamicOptionsTest < MiniTest::Spec
#   module Model
#     Song  = Struct.new(:title, :composer)
#     Album = Struct.new(:id, :name, :songs, :artist)
#     Artist = Struct.new(:name, :hidden_taste)
#   end


#   module Twin
#     class Album < Disposable::Twin
#       feature Setup
#       feature Sync
#       # feature Changed

#       property :id,   sync: true
#       property :name, sync: true

#       collection :songs ,
#          sync: lambda { |value, options|  } do # FIXME: this is called before the songs items where synced?
#         property :title, sync: lambda { |value, options| value == "Empty Rooms" ? model.title= "++#{value}" : nil }
#       end

#       property :artist, sync: true do
#         property :name
#       end
#     end
#   end


#   # sync does NOT call setter.
#   describe ":sync allows you conditionals and is run in twin context" do
#     let (:album) { Model::Album.new(1, "Corridors Of Power", [song, song_with_composer], artist) }
#     let (:song) { Model::Song.new() }
#     let (:song_with_composer) { Model::Song.new("American Jesus", composer) }
#     let (:composer) { Model::Artist.new(nil) }
#     let (:artist) { Model::Artist.new("Bad Religion") }

#     let (:twin) { Twin::Album.new(album) }

#     it do
#       album.instance_exec { def id=(*);    raise "don't call me!"; end }
#       song.instance_exec  { def title=(*); raise "don't call me!"; end }

#       # triggers :sync.
#       twin.name = "Run For Cover"

#       twin.songs[1].title = "Empty Rooms" # song_with_composer. this will trigger the #title= writer.
#       twin.artist.name = "Gary Moore"

#       twin.sync(
#         id:     lambda { |value, options| nil },
#         name:   lambda { |value, options| options.user_options[:twin].model.name= "processed+#{value}" },

#         artist: lambda { |twin, options| twin.model.hidden_taste = "Ska" },
#       )

#       # Album#id :sync was called, nothing happened.
#       album.id.must_equal 1
#       # Album#name :sync was called, first case.
#       album.name.must_equal "processed+Run For Cover"
#       # Song#title :sync called but returns nil.
#       song.title.must_be_nil
#       # Song#title :sync called and processed, first case.
#      #### song_with_composer.title.must_equal "++Empty Rooms"

#       # Artist#name :sync was called.
#       artist.name.must_equal "Gary Moore"
#       # Album#artist :sync was called.
#       artist.hidden_taste.must_equal "Ska"
#     end
#   end
# end


# class SyncWithOptionsAndSkipUnchangedTest < MiniTest::Spec
#   module Model
#     Song  = Struct.new(:title, :composer)
#     Album = Struct.new(:id, :name, :songs, :artist)
#     Artist = Struct.new(:name)
#   end


#   module Twin
#     class Album < Disposable::Twin
#       feature Setup
#       feature Sync
#       feature Sync::SkipUnchanged

#       property :id
#       property :name

#       collection :songs do # FIXME: this is called before the songs items where synced?
#         property :title
#       end

#       # only execute this when changed.
#       property :artist, sync: lambda { |artist_twin, options| model.artist.name = "#{artist_twin.name}+" } do
#         property :name
#       end
#     end
#   end

#   let (:album) { Model::Album.new(1, "Corridors Of Power", [], artist) }
#   # let (:song) { Model::Song.new() }
#   # let (:song_with_composer) { Model::Song.new("American Jesus", composer) }
#   # let (:composer) { Model::Artist.new(nil) }
#   let (:artist) { Model::Artist.new("Bad Religion") }

#   it do
#     twin = Twin::Album.new(album)

#     twin.artist.name.must_equal "Bad Religion"
#     twin.sync
#     twin.artist.name.must_equal "Bad Religion"

#     twin.artist.name= "Greg Howe"
#     twin.sync
#     artist.name.must_equal "Greg Howe+"
#   end
# end

# # :virtual wins over :sync
# # class SyncWithVirtualTest < MiniTest::Spec
# #   Song = Struct.new(:title, :image, :band)
# #   Band = Struct.new(:name)

# #   let (:form) { HitForm.new(song) }
# #   let (:song) { Song.new("Injection", Object, Band.new("Rise Against")) }

# #   class HitForm < Disposable::Twin
# #     include Sync::SkipUnchanged
# #     register_feature Sync::SkipUnchanged

# #     property :image, sync: lambda { |value, *| model.image = "processed via :sync: #{value}" }
# #     property :band do
# #       property :name, sync: lambda { |value, *| model.name = "band, processed: #{value}" }, virtual: true
# #     end
# #   end

# #   it "abc" do
# #     form.validate("image" => "Funny photo of Steve Harris", "band" => {"name" => "Iron Maiden"}).must_equal true

# #     form.sync
# #     song.image.must_equal "processed via :sync: Funny photo of Steve Harris"
# #     song.band.name.must_equal "Rise Against"
# #   end
# # end

