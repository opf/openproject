require 'spec_helper.rb'

describe AttrOptional do
  before do
    @a, @b, @c = A.new, B.new, C.new
  end

  describe '.attr_optional' do
    it 'should define accessible attributes' do
      @a.should respond_to :attr_optional_a
      @a.should respond_to :attr_optional_a=
      @b.should respond_to :attr_optional_b
      @b.should respond_to :attr_optional_b=
    end

    it 'should be inherited' do
      @b.should respond_to :attr_optional_a
      @b.should respond_to :attr_optional_a=
    end

    context 'when already required' do
      it 'should be optional' do
        @c.attr_required?(:attr_required_b).should == false
        @c.attr_optional?(:attr_required_b).should == true
      end
    end

    context 'when AttrRequired not included' do
      it 'should do nothing' do
        OnlyOptional.optional_attributes.should == [:only_optional]
      end
    end
  end

  describe '.attr_optional?' do
    it 'should answer whether the attributes is optional or not' do
      A.attr_optional?(:attr_optional_a).should == true
      B.attr_optional?(:attr_optional_a).should == true
      B.attr_optional?(:attr_optional_b).should == true
      B.attr_optional?(:to_s).should == false
    end
  end

  describe '#attr_optional?' do
    it 'should answer whether the attributes is optional or not' do
      @a.attr_optional?(:attr_optional_a).should == true
      @b.attr_optional?(:attr_optional_a).should == true
      @b.attr_optional?(:attr_optional_b).should == true
      @b.attr_optional?(:to_s).should == false
    end
  end

  describe '.optional_attributes' do
    it 'should return all optional attributes keys' do
      A.optional_attributes.should == [:attr_optional_a]
      B.optional_attributes.should == [:attr_optional_a, :attr_optional_b]
    end
  end

  describe '#optional_attributes' do
    it 'should return optional attributes keys' do
      @a.optional_attributes.should == [:attr_optional_a]
      @b.optional_attributes.should == [:attr_optional_a, :attr_optional_b]
    end
  end

  describe '.undef_optional_attributes' do
    it 'should undefine accessors and remove from optional attributes' do
      C.optional_attributes.should_not include :attr_optional_a
      @c.optional_attributes.should_not include :attr_optional_a
      @c.should_not respond_to :attr_optional_a
      @c.should_not respond_to :attr_optional_a=
    end
  end
end
