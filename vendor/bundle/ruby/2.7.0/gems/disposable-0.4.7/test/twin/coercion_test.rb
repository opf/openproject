require "test_helper"

require "disposable/twin/coercion"

class CoercionTest < MiniTest::Spec
  class TwinWithSkipSetter < Disposable::Twin
    feature Coercion
    feature Setup::SkipSetter

    property :id
    property :released_at, type: DRY_TYPES_CONSTANT::DateTime

    property :hit do
      property :length, type: const_get("Types::Coercible::#{DRY_TYPES_INT_CONSTANT}")
      property :good,   type: Types::Bool
    end

    property :band do
      property :label do
        property :value, type: Types::Coercible::Float
      end
    end
  end

  describe "with Setup::SkipSetter" do
    subject do
      TwinWithSkipSetter.new(album)
    end

    let (:album) {
      OpenStruct.new(
        id: 1,
        :released_at => "31/03/1981",
        :hit         => OpenStruct.new(:length => "312"),
        :band        => OpenStruct.new(:label => OpenStruct.new(:value => "9999.99"))
      )
    }

    it "NOT coerce values in setup" do
      expect(subject.released_at).must_equal "31/03/1981"
      expect(subject.hit.length).must_equal "312"
      expect(subject.band.label.value).must_equal "9999.99"
    end


    it "coerce values when using a setter" do
      subject.id = Object
      subject.released_at = "30/03/1981"
      subject.hit.length = "312"
      subject.band.label.value = "9999.99"

      expect(subject.released_at).must_be_kind_of DateTime
      expect(subject.released_at).must_equal DateTime.parse("30/03/1981")
      expect(subject.hit.length).must_equal 312
      expect(subject.hit.good).must_be_nil
      expect(subject.band.label.value).must_equal 9999.99
    end
  end

  class TwinWithoutSkipSetter < Disposable::Twin
    feature Coercion
    property :id, type: const_get("Types::Coercible::#{DRY_TYPES_INT_CONSTANT}")
  end

  describe "without Setup::SkipSetter" do

    subject do
      TwinWithoutSkipSetter.new(OpenStruct.new(id: "1"))
    end

    it "coerce values in setup and when using a setter" do
      expect(subject.id).must_equal 1
      subject.id = "2"
      expect(subject.id).must_equal 2
    end
  end

  class TwinWithNilify < Disposable::Twin
    feature Coercion

    property :date_of_birth,
             type: DRY_TYPES_CONSTANT::Date, nilify: true
    property :date_of_death_by_unicorns,
             type: DRY_TYPES_CONSTANT::Nil | DRY_TYPES_CONSTANT::Date
    property :id, type: const_get("Types::Coercible::#{DRY_TYPES_INT_CONSTANT}"), nilify: true
  end

  class TwinWithoutTypeWithNilify < Disposable::Twin
    feature Coercion

    property :date_of_birth, nilify: true
    property :date_of_death_by_unicorns, type: DRY_TYPES_CONSTANT::Nil | DRY_TYPES_CONSTANT::Date
    property :id, type: const_get("Types::Coercible::#{DRY_TYPES_INT_CONSTANT}"), nilify: true
  end

  describe "with Nilify" do
    subject do
      TwinWithNilify.new(OpenStruct.new(date_of_birth: '1990-01-12',
                                        date_of_death_by_unicorns: '2037-02-18',
                                        id: 1))
    end

    it "coerce values correctly" do
      expect(subject.date_of_birth).must_equal Date.parse('1990-01-12')
      expect(subject.date_of_death_by_unicorns).must_equal Date.parse('2037-02-18')
    end

    it "coerce empty values to nil when using option nilify: true" do
      subject.date_of_birth = ""
      expect(subject.date_of_birth).must_be_nil
    end

    it "coerce empty values to nil when using dry-types | operator" do
      subject.date_of_death_by_unicorns = ""
      expect(subject.date_of_death_by_unicorns).must_be_nil
    end

    it "converts blank string to nil, without :type option" do
      subject.id = ""
      expect(subject.id).must_be_nil
    end
  end

  describe "without Type With Nilify" do
    let(:date_of_birth) { '1990-01-12' }
    subject do
      TwinWithoutTypeWithNilify.new(
        OpenStruct.new(
          date_of_birth: date_of_birth,
          date_of_death_by_unicorns: '2037-02-18',
          id: 1
        )
      )
    end

    it 'raise error for new dry-types v - work as expected for older versions' do
      if Disposable::Twin::Coercion::DRY_TYPES_VERSION >= Gem::Version.new("1.0")
        assert_raises(Dry::Types::CoercionError) { subject.date_of_birth }
        assert_raises(Dry::Types::CoercionError) { subject.date_of_death_by_unicorns }
      else
        expect(subject.date_of_birth).must_equal '1990-01-12'
        expect(subject.date_of_death_by_unicorns).must_equal Date.parse('2037-02-18')
      end
    end

    describe 'when passing nil' do
      let(:date_of_birth) { '' }

      it 'coerce values correctly' do
        expect(subject.date_of_birth).must_be_nil
      end
    end
  end
end

# this converts "" to nil and then breaks because it's strict.
# Types::Strict::String.constructor(Dry::Types::Params.method(:to_nil))

class CoercionTypingTest < MiniTest::Spec
  class Song < Disposable::Twin
    include Coercion
    include Setup::SkipSetter

    # property :title, type: Dry::Types::Strict::String.constructor(Dry::Types::Params.method(:to_nil))
    property :title, type: Types::Strict::String.optional # this is the behavior of the "DB" data twin. this is NOT the form.

    # property :name, type: Types::Params::String
  end

  it do
    twin = Song.new(Struct.new(:title, :name).new)

    # with type: Dry::Types::Strict::String
    # assert_raises(Dry::Types::ConstraintError) { twin.title = nil }
    twin.title = nil
    expect(twin.title).must_be_nil

    twin.title = "Yo"
    expect(twin.title).must_equal "Yo"

    twin.title = ""
    expect(twin.title).must_equal ""

    assert_raises(Dry::Types::ConstraintError) { twin.title = :bla }
    assert_raises(Dry::Types::ConstraintError) { twin.title = 1 }
  end

  # Form
  class Form < Disposable::Twin
    include Coercion
    include Setup::SkipSetter


    # property :title, type: Dry::Types::Strict::String.constructor(Dry::Types::Params.method(:to_nil))

    property :title, type: DRY_TYPES_CONSTANT::Nil | Types::Strict::String # this is the behavior of the "DB" data twin. this is NOT the form.

    # property :name, type: Types::Params::String

    property :enabled, type: DRY_TYPES_CONSTANT::Bool
    # property :enabled, Bool.constructor(:trim!)
  end
  it do
    twin =Form.new(Struct.new(:title, :enabled).new)

    # assert_raises(Dry::Types::ConstraintError) { twin.title = nil } # in form, we either have a blank string or the key's not present at all.
    twin.title = nil
    expect(twin.title).must_be_nil

    twin.title = "" # nilify blank strings
    expect(twin.title).must_be_nil

    twin.title = "Yo"
    expect(twin.title).must_equal "Yo"

    # twin.enabled = " TRUE"
    #expect(twin.enabled).must_equal true
  end
end


# def title=(String value) # allow obj.title = "bla"
# def title=(Nil)          # allow obj.title = nil



# active = " TRUE HACK"
# how to test/validate if active is boolean?

