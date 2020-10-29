# require "test_helper"

# class ProcessInlineTest < MiniTest::Spec
#   Album = Struct.new(:artist, :composer, :recursive_composer)

#   module InlineTwin
#   end

#   class RecursiveComposerTwin < Disposable::Twin
#     property :composer, twin: self
#   end

#   class AlbumTwin < Disposable::Twin
#     def self.process_inline!(inline_class, definition)
#       inline_class.send :include, InlineTwin
#     end

#     property :artist do
#     end

#     property :composer, twin: ->{ ComposerTwin }

#     property :recursive_composer, twin: RecursiveComposerTwin
#   end

#   class ComposerTwin < Disposable::Twin
#   end

#   it do
#     twin = AlbumTwin.new(Album.new(Object, Object))
#     assert ! (twin.class < InlineTwin)
#     assert   (twin.artist.class < InlineTwin)
#     assert ! (twin.composer.class < InlineTwin)
#   end
# end