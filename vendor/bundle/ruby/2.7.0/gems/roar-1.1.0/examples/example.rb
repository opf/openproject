#!/usr/bin/env ruby

require 'bundler'
Bundler.setup

require 'ostruct'
require 'roar/json'

def reset_representer(*module_name)
  module_name.each do |mod|
    mod.module_eval do
      @representable_attrs = nil
    end
  end
end


class Song < OpenStruct
end

module SongRepresenter
  include Roar::JSON

  property :title
end

song = Song.new(title: 'Fate').extend(SongRepresenter)
puts song.to_json

# Parsing

song = Song.new.extend(SongRepresenter)
song.from_json('{"title":"Linoleum"}')
puts song.title


# Decorator

require 'roar/decorator'

module Decorator
  class SongRepresenter < Roar::Decorator
    include Roar::JSON

    property :title
  end
end

song = Song.new(title: 'Medicine Balls')
puts Decorator::SongRepresenter.new(song).to_json

# Collections

reset_representer(SongRepresenter)

module SongRepresenter
  include Roar::JSON

  property :title
  collection :composers
end


song = Song.new(title: 'Roxanne', composers: ['Sting', 'Stu Copeland'])
song.extend(SongRepresenter)
puts song.to_json

# Nesting

class Album < OpenStruct
end

module AlbumRepresenter
  include Roar::JSON

  property :title
  collection :songs, extend: SongRepresenter, class: Song
end

album = Album.new(title: 'True North', songs: [Song.new(title: 'The Island'), Song.new(:title => 'Changing Tide')])
album.extend(AlbumRepresenter)
puts album.to_json

album = Album.new
album.extend(AlbumRepresenter)

album.from_json('{"title":"Indestructible","songs":[{"title":"Tropical London"},{"title":"Roadblock"}]}')

puts album.songs.last.inspect

reset_representer(AlbumRepresenter)

module AlbumRepresenter
  include Roar::JSON

  property :title

  collection :songs, class: Song do
    property :title
  end
end

album = Album.new(title: 'True North', songs: [Song.new(title: 'The Island'), Song.new(:title => 'Changing Tide')])
album.extend(AlbumRepresenter)
puts album.to_json

album = Album.new
album.extend(AlbumRepresenter)
album.from_json('{"title":"True North","songs":[{"title":"The Island"},{"title":"Changing Tide"}]}')
puts album.title
puts album.songs.first.title

# parse_strategy: :sync

reset_representer(AlbumRepresenter)

module AlbumRepresenter
  include Roar::JSON

  property :title

  collection :songs, extend: SongRepresenter, parse_strategy: :sync
end


album = Album.new(title: 'True North', songs: [Song.new(title: 'The Island'), Song.new(:title => 'Changing Tide')])
album.extend(AlbumRepresenter)

puts album.songs[0].object_id
album.from_json('{"title":"True North","songs":[{"title":"Secret Society"},{"title":"Changing Tide"}]}')
puts album.songs[0].title
puts album.songs[0].object_id

# Coercion, renaming, ..

# Hypermedia

reset_representer(SongRepresenter)

module SongRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :title

  link :self do
    "http://songs/#{title}"
  end
end

song.extend(SongRepresenter)
puts song.to_json

# roar-rails and URL helpers


# Passing options into link

reset_representer(SongRepresenter)

module SongRepresenter
  include Roar::JSON

  property :title

  link :self do |opts|
    "http://#{opts[:base_url]}songs/#{title}"
  end
end

song.extend(SongRepresenter)
puts song.to_json(base_url: 'localhost:3001/')


# Discovering Hypermedia

song = Song.new.extend(SongRepresenter)
song.from_json('{"title":"Roxanne","links":[{"rel":"self","href":"http://songs/Roxanne"}]}')
puts song.links[:self].href

# Media Formats: HAL

require 'roar/json/hal'

module HAL
  module SongRepresenter
    include Roar::JSON::HAL

    property :title

    link :self do
      "http://songs/#{title}"
    end
  end
end

song.extend(HAL::SongRepresenter)
puts song.to_json

reset_representer(AlbumRepresenter)

module AlbumRepresenter
  include Roar::JSON::HAL

  property :title

  collection :songs, class: Song, embedded: true do
    property :title
  end
end

album = Album.new(title: 'True North', songs: [Song.new(title: 'The Island'), Song.new(:title => 'Changing Tide')])
album.extend(AlbumRepresenter)
puts album.to_json

# Media Formats: JSON+Collection

require 'roar/json/collection_json'


module Collection
  module SongRepresenter
    include Roar::JSON::CollectionJSON
    version '1.0'
    href { 'http://localhost/songs/' }

    property :title

    items(:class => Song) do
      href { "//songs/#{title}" }

      property :title, :prompt => 'Song title'

      link(:download) { "//songs/#{title}.mp3" }
    end

    template do
      property :title, :prompt => 'Song title'
    end

    queries do
      link :search do
        {:href => '//search', :data => [{:name => 'q', :value => ''}]}
      end
    end
  end
end

song = Song.new(title: 'Roxanne')
song.extend(Collection::SongRepresenter)
puts song.to_json

# Client-side
# share in gem, parse existing document.

reset_representer(SongRepresenter)

module SongRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :title
  property :id

  link :self do
    "http://songs/#{title}"
  end
end


require 'roar/client'

module Client
  class Song < OpenStruct
    include Roar::JSON
    include SongRepresenter
    include Roar::Client
  end
end

song = Client::Song.new(title: 'Roxanne')
song.post(uri: 'http://localhost:4567/songs', as: 'application/json')
puts song.id


song = Client::Song.new
song.get(uri: 'http://localhost:4567/songs/1', as: 'application/json')
puts song.title
puts song.links[:self].href

# XML

require 'roar/xml'

module XML
  module SongRepresenter
    include Roar::XML
    include Roar::Hypermedia

    property :title
    property :id

    link :self do
      "http://songs/#{title}"
    end
  end
end

song = Song.new(title: 'Roxanne', id: 42)
song.extend(XML::SongRepresenter)
puts song.to_xml

# Coercion

reset_representer(SongRepresenter)

require 'roar/coercion'

module SongRepresenter
  include Roar::JSON
  include Roar::Coercion

  property :title
  property :released_at, type: DateTime
end

song = Song.new
song.extend(SongRepresenter)
song.from_json('{"released_at":"1981/03/31"}')

puts song.released_at


class LinkOptionsCollection < Array

end

module HyperlinkiRepresenter
  include Roar::JSON

  def to_hash(*)  # setup the link
    # FIXME: why does self.to_s throw a stack level too deep (SystemStackError) ?
    "#{self}"
    # how would the Link instance get access to its Definition in order to execute the block?
  end
end

module Representer
  include Roar::JSON

  def self.links
    [:self, :next]
  end

  collection :links, :extend => HyperlinkiRepresenter

  def links
    # get link configurations from representable_attrs object.
    #self.representable_attrs.links
    LinkOptionsCollection.new(['self', 'next'])
  end
end

puts ''.extend(Representer).to_json