# run me with bundle exec ruby -Itest test/example.rb

require "test_helper"

ActiveRecord::Base.logger = Logger.new(STDOUT)

module Twin
  class Album < Disposable::Twin
    property :id # DISCUSS: needed for #save.
    property :name
    collection :songs, :twin => lambda { |*| Song }

    extend Representer
    include Setup
    include Sync
  end

  class Song < Disposable::Twin
    property :id # DISCUSS: needed for #save.
    property :title
    # property :album, :twin => Album

    extend Representer
    include Setup
    include Sync
  end
end

album = Album.last

twin = Twin::Album.new(album)
puts "existing songs (#{twin.songs.size}): #{twin.songs.inspect}"

# this is what basically should happen in the representer, returning a Twin.
twin.songs << Song.new
twin.songs.last.title = "Back To Allentown"

puts "new songs (#{twin.songs.size}): #{twin.songs.inspect}"

twin.sync