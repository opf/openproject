require 'minitest/autorun'
require 'mimemagic'
require 'stringio'
require 'forwardable'

class TestMimeMagic < Minitest::Test
  # Do deep copy for constants of initial state.
  INIT_EXTENSIONS = Marshal.load(Marshal.dump(MimeMagic::EXTENSIONS))
  INIT_TYPES = Marshal.load(Marshal.dump(MimeMagic::TYPES))
  INIT_MAGIC = Marshal.load(Marshal.dump(MimeMagic::MAGIC))

  def setup
    extentions = Marshal.load(Marshal.dump(INIT_EXTENSIONS))
    types = Marshal.load(Marshal.dump(INIT_TYPES))
    magic = Marshal.load(Marshal.dump(INIT_MAGIC))
    MimeMagic.send(:remove_const, :EXTENSIONS) if MimeMagic.const_defined?(:EXTENSIONS)
    MimeMagic.send(:remove_const, :TYPES) if MimeMagic.const_defined?(:TYPES)
    MimeMagic.send(:remove_const, :MAGIC) if MimeMagic.const_defined?(:MAGIC)
    MimeMagic.const_set('EXTENSIONS', extentions)
    MimeMagic.const_set('TYPES', types)
    MimeMagic.const_set('MAGIC', magic)
  end

  def test_have_type_mediatype_and_subtype
    assert_equal 'text/html', MimeMagic.new('text/html').type
    assert_equal 'text', MimeMagic.new('text/html').mediatype
    assert_equal 'html', MimeMagic.new('text/html').subtype
  end

  def test_have_mediatype_helpers
    assert MimeMagic.new('text/plain').text?
    assert MimeMagic.new('text/html').text?
    assert MimeMagic.new('application/xhtml+xml').text?
    refute MimeMagic.new('application/octet-stream').text?
    refute MimeMagic.new('image/png').text?
    assert MimeMagic.new('image/png').image?
    assert MimeMagic.new('video/ogg').video?
    assert MimeMagic.new('audio/mpeg').audio?
  end

  def test_have_hierarchy
    assert MimeMagic.new('text/html').child_of?('text/plain')
    assert MimeMagic.new('text/x-java').child_of?('text/plain')
  end

  def test_have_extensions
    assert_equal %w(htm html), MimeMagic.new('text/html').extensions
  end

  def test_have_comment
    assert_equal 'HTML document', MimeMagic.new('text/html').comment
  end

  def test_recognize_extensions
    assert_equal 'text/html', MimeMagic.by_extension('.html').to_s
    assert_equal 'text/html', MimeMagic.by_extension('html').to_s
    assert_equal 'text/html', MimeMagic.by_extension(:html).to_s
    assert_equal 'application/x-ruby', MimeMagic.by_extension('rb').to_s
    assert_nil MimeMagic.by_extension('crazy')
    assert_nil MimeMagic.by_extension('')
  end

  def test_recognize_by_a_path
    assert_equal 'text/html', MimeMagic.by_path('/adsjkfa/kajsdfkadsf/kajsdfjasdf.html').to_s
    assert_equal 'text/html', MimeMagic.by_path('something.html').to_s
    assert_equal 'application/x-ruby', MimeMagic.by_path('wtf.rb').to_s
    assert_nil MimeMagic.by_path('where/am.html/crazy')
    assert_nil MimeMagic.by_path('')
  end

  def test_recognize_xlsx_as_zip_without_magic
    file = "test/files/application.vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    %w(msoffice rubyxl gdocs).each do |variant|
      file = "test/files/application.vnd.openxmlformats-officedocument.spreadsheetml{#{variant}}.sheet"
      assert_equal "application/zip", MimeMagic.by_magic(File.read(file)).to_s
      assert_equal "application/zip", MimeMagic.by_magic(File.open(file, 'rb')).to_s
    end
  end

  def test_recognize_by_magic
    load "mimemagic/overlay.rb"
    Dir['test/files/*'].each do |file|
      mime = file[11..-1].sub('.', '/').sub(/\{\w+\}/, '')
      assert_equal mime, MimeMagic.by_magic(File.read(file)).to_s
      assert_equal mime, MimeMagic.by_magic(File.open(file, 'rb')).to_s
    end
  end

  def test_recognize_all_by_magic
    load 'mimemagic/overlay.rb'
    %w(msoffice rubyxl gdocs).each do |variant|
      file = "test/files/application.vnd.openxmlformats-officedocument.spreadsheetml{#{variant}}.sheet"
      mimes = %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/zip]
      assert_equal mimes, MimeMagic.all_by_magic(File.read(file)).map(&:type)
    end
  end

  def test_have_add
    MimeMagic.add('application/mimemagic-test',
                  extensions: %w(ext1 ext2),
                  parents: 'application/xml',
                  comment: 'Comment')
    assert_equal 'application/mimemagic-test', MimeMagic.by_extension('ext1').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_extension('ext2').to_s
    assert_equal 'Comment', MimeMagic.by_extension('ext2').comment
    assert_equal %w(ext1 ext2), MimeMagic.new('application/mimemagic-test').extensions
    assert MimeMagic.new('application/mimemagic-test').child_of?('text/plain')
  end

  def test_process_magic
    MimeMagic.add('application/mimemagic-test',
                  magic: [[0, 'MAGICTEST'], # MAGICTEST at position 0
                             [1, 'MAGICTEST'], # MAGICTEST at position 1
                             [9..12, 'MAGICTEST'], # MAGICTEST starting at position 9 to 12
                             [2, 'MAGICTEST', [[0, 'X'], [0, 'Y']]]]) # MAGICTEST at position 2 and (X at 0 or Y at 0)

    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('XMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(' MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('123456789MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('123456789ABMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('123456789ABCMAGICTEST').to_s
    assert_nil MimeMagic.by_magic('123456789ABCDMAGICTEST')
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('X MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic('Y MAGICTEST').to_s
    assert_nil MimeMagic.by_magic('Z MAGICTEST')

    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'XMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new ' MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new '123456789MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new '123456789ABMAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new '123456789ABCMAGICTEST').to_s
    assert_nil MimeMagic.by_magic(StringIO.new '123456789ABCDMAGICTEST')
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'X MAGICTEST').to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringIO.new 'Y MAGICTEST').to_s
    assert_nil MimeMagic.by_magic(StringIO.new 'Z MAGICTEST')
  end

  class IOObject
    def initialize
      @io = StringIO.new('MAGICTEST')
    end

    extend Forwardable
    delegate [:read, :size, :rewind, :eof?, :close] => :@io
  end

  class StringableObject
    def to_s
      'MAGICTEST'
    end
  end

  def test_handle_different_file_objects
    MimeMagic.add('application/mimemagic-test', magic: [[0, 'MAGICTEST']])
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(IOObject.new).to_s
    assert_equal 'application/mimemagic-test', MimeMagic.by_magic(StringableObject.new).to_s
  end
end
