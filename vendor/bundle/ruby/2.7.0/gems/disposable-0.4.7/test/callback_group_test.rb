require "test_helper"
require "disposable/callback"

class CallbackGroupTest < MiniTest::Spec
  class Group < Disposable::Callback::Group
    attr_reader :output

    on_change :change!

    collection :songs do
      on_add :notify_album!
      on_add :reset_song!

      # on_delete :notify_deleted_author! # in Update!

      def notify_album!(twin, options)
        options[:content] << "notify_album!"
      end

      def reset_song!(twin, options)
        options[:content] << "reset_song!"
      end
    end

    on_change :rehash_name!, property: :title


    on_create :expire_cache! # on_change
    on_update :expire_cache!

    def change!(twin, options)
      @output = "Album has changed!"
    end
  end


  class AlbumTwin < Disposable::Twin
    feature Sync, Save
    feature Persisted, Changed

    property :name

    property :artist do
      property :name
    end

    collection :songs do
      property :title
    end
  end


  # empty.
  it do
    album = Album.new(songs: [Song.new(title: "Dead To Me"), Song.new(title: "Diesel Boy")])
    twin  = AlbumTwin.new(album)

    expect(Group.new(twin).().invocations).must_equal [
      [:on_change, :change!, []],
      [:on_add, :notify_album!, []],
      [:on_add, :reset_song!, []],
      [:on_change, :rehash_name!, []],
      [:on_create, :expire_cache!, []],
      [:on_update, :expire_cache!, []],
    ]
  end

  # trigger songs:on_add, and on_change.
  let (:content) { "" }
  it do
    twin = AlbumTwin.new(Album.new)
    twin.songs << Song.new(title: "Dead To Me")
    twin.songs << Song.new(title: "Diesel Boy")

    twin.name = "Dear Landlord"

    group = Group.new(twin).(content: content)

    expect(group.invocations).must_equal [
      [:on_change, :change!, [twin]],
      [:on_add, :notify_album!, [twin.songs[0], twin.songs[1]]],
      [:on_add, :reset_song!,   [twin.songs[0], twin.songs[1]]],
      [:on_change, :rehash_name!, []],
      [:on_create, :expire_cache!, []],
      [:on_update, :expire_cache!, []],
    ]

    expect(content).must_equal "notify_album!notify_album!reset_song!reset_song!"
    expect(group.output).must_equal "Album has changed!"
  end





  # context.
  class Operation
    attr_reader :output

    def change!(twin, options)
      options[:content] << "Op: changed! [#{options[:context].class}]"
    end

    def notify_album!(twin, options)
      options[:content] << "Op: notify_album! [#{options[:context].class}]"
    end

    def reset_song!(twin, options)
      options[:content] << "Op: reset_song! [#{options[:context].class}]"
    end

    def rehash_name!(twin, options)
      options[:content] << "Op: rehash_name! [#{options[:context].class}]"
    end

    def expire_cache!(twin, options)
      options[:content] << "Op: expire_cache! [#{options[:context].class}]"
    end
  end

  it do
    twin = AlbumTwin.new(Album.new)
    twin.songs << Song.new(title: "Dead To Me")

    twin.name = "Dear Landlord"

    group = Group.new(twin).(context: Operation.new, content: content)
    # Disposable::Callback::Dispatch.new(twin).on_change{ |twin| puts twin;puts }

    # pp group.invocations

    expect(group.invocations).must_equal [
      [:on_change, :change!, [twin]],
      [:on_add, :notify_album!, [twin.songs[0]]],
      [:on_add, :reset_song!,   [twin.songs[0]]],
      [:on_change, :rehash_name!, []],
      [:on_create, :expire_cache!, []],
      [:on_update, :expire_cache!, []],
    ]

    expect(content).must_equal "Op: changed! [CallbackGroupTest::Operation]Op: notify_album! [CallbackGroupTest::Operation]Op: reset_song! [CallbackGroupTest::Operation]"
  end
end


class CallbackGroupInheritanceTest < MiniTest::Spec
  class Group < Disposable::Callback::Group
    on_change :change!
    collection :songs do
      on_add :notify_album!
      on_add :reset_song!
    end
    on_change :rehash_name!, property: :title
    property :artist do
      on_change :sing!
    end
  end

  it do
    expect(Group.hooks.size).must_equal 4
    expect(Group.hooks[0].to_s).must_equal "[:on_change, :change!, {}]"
    # Group.hooks[1][1][:nested].hooks.to_s.must_equal "[[:on_add, [:notify_album!]],[:on_add, [:reset_song!]]]"
    expect(Group.hooks[2].to_s).must_equal "[:on_change, :rehash_name!, {:property=>:title}]"

    expect(Group.definitions.get(Group.hooks[3][1])[:nested].hooks.to_s).must_equal "[[:on_change, :sing!, {}]]"
  end

  class EmptyGroup < Group
  end



  it do
    expect(EmptyGroup.hooks.size).must_equal 4
    # TODO:
  end

  class EnhancedGroup < Group
    on_change :redo!
    collection :songs do
      on_add :rewind!
    end
  end

  it do
    expect(Group.hooks.size).must_equal 4
    # pp EnhancedGroup.hooks
    expect(EnhancedGroup.hooks.size).must_equal 6
    expect(EnhancedGroup.definitions.get(EnhancedGroup.hooks[5][1])[:nested].hooks.to_s).must_equal "[[:on_add, :rewind!, {}]]"
  end

  class EnhancedWithInheritGroup < EnhancedGroup
    collection :songs, inherit: true do # finds first.
      on_add :eat!
    end
    property :artist, inherit: true do
      on_delete :yell!
    end
  end

  it do
    expect(Group.hooks.size).must_equal 4
    expect(EnhancedGroup.hooks.size).must_equal 6

    expect(EnhancedGroup.definitions.get(EnhancedGroup.hooks[5][1])[:nested].hooks.to_s).must_equal "[[:on_add, :rewind!, {}]]"
    expect(EnhancedWithInheritGroup.hooks.size).must_equal 6
    expect(EnhancedWithInheritGroup.definitions.get(EnhancedWithInheritGroup.hooks[1][1])[:nested].hooks.to_s).must_equal "[[:on_add, :rewind!, {}], [:on_add, :eat!, {}]]"
    expect(EnhancedWithInheritGroup.definitions.get(EnhancedWithInheritGroup.hooks[3][1])[:nested].hooks.to_s).must_equal "[[:on_change, :sing!, {}], [:on_delete, :yell!, {}]]"
  end

  class RemovingInheritGroup < Group
    remove! :on_change, :change!
    collection :songs, inherit: true do # this will not change position
      remove! :on_add, :notify_album!
    end
  end

# # puts "@@@@@ #{Group.hooks.object_id.inspect}"
# # puts "@@@@@ #{EmptyGroup.hooks.object_id.inspect}"
# puts "@@@@@ Group:         #{Group.definitions.get(:songs)[:nested].hooks.inspect}"
# puts "@@@@@ EnhancedGroup: #{EnhancedGroup.definitions.get(:songs)[:nested].hooks.inspect}"
# puts "@@@@@ InheritGroup:  #{EnhancedWithInheritGroup.definitions.get(:songs)[:nested].hooks.inspect}"
# puts "@@@@@ RemovingGroup: #{RemovingInheritGroup.definitions.get(:songs)[:nested].hooks.inspect}"
# # puts "@@@@@ #{EnhancedWithInheritGroup.definitions.get(:songs)[:nested].hooks.object_id.inspect}"

  # TODO: object_id tests for all nested representers.

  it do
    expect(Group.hooks.size).must_equal 4
    expect(RemovingInheritGroup.hooks.size).must_equal 3
    expect(RemovingInheritGroup.definitions.get(RemovingInheritGroup.hooks[0][1])[:nested].hooks.to_s).must_equal "[[:on_add, :reset_song!, {}]]"
    expect(RemovingInheritGroup.definitions.get(RemovingInheritGroup.hooks[2][1])[:nested].hooks.to_s).must_equal "[[:on_change, :sing!, {}]]"
  end

  # Group::clone
  ClonedGroup = Group.clone
  ClonedGroup.class_eval do
    remove! :on_change, :change!
  end

  it do
    expect(Group.hooks.size).must_equal 4
    expect(ClonedGroup.hooks.size).must_equal 3
  end
end
