require 'spec_helper.rb'

describe AttrRequired do
  before do
    @a, @b, @c = A.new, B.new, C.new
  end

  describe '.attr_required' do
    it 'should define accessible attributes' do
      @a.should respond_to :attr_required_a
      @a.should respond_to :attr_required_a=
      @b.should respond_to :attr_required_b
      @b.should respond_to :attr_required_b=
    end

    it 'should be inherited' do
      @b.should respond_to :attr_required_a
      @b.should respond_to :attr_required_a=
    end

    context 'when already optional' do
      it 'should be optional' do
        @c.attr_required?(:attr_optional_b).should == true
        @c.attr_optional?(:attr_optional_b).should == false
      end
    end

    context 'when AttrOptional not included' do
      it 'should do nothing' do
        OnlyRequired.required_attributes.should == [:only_required]
      end
    end
  end

  describe '.attr_required?' do
    it 'should answer whether the attributes is required or not' do
      A.attr_required?(:attr_required_a).should == true
      B.attr_required?(:attr_required_a).should == true
      B.attr_required?(:attr_required_b).should == true
      B.attr_required?(:to_s).should == false
    end
  end

  describe '#attr_required?' do
    it 'should answer whether the attributes is required or not' do
      @a.attr_required?(:attr_required_a).should == true
      @b.attr_required?(:attr_required_a).should == true
      @b.attr_required?(:attr_required_b).should == true
      @a.attr_required?(:attr_required_b).should == false
      @b.attr_required?(:to_s).should == false
    end
  end

  describe '#attr_missing?' do
    it 'should answer whether any attributes are missing' do
      @a.attr_missing?.should == true
      @b.attr_missing?.should == true
      @a.attr_required_a = 'attr_required_a'
      @b.attr_required_a = 'attr_required_a'
      @a.attr_missing?.should == false
      @b.attr_missing?.should == true
      @b.attr_required_b = 'attr_required_b'
      @b.attr_missing?.should == false
    end
  end

  describe '#attr_missing!' do
    it 'should raise AttrMissing error when any attributes are missing' do
      lambda { @a.attr_missing! }.should raise_error(AttrRequired::AttrMissing)
      lambda { @b.attr_missing! }.should raise_error(AttrRequired::AttrMissing)
      @a.attr_required_a = 'attr_required_a'
      @b.attr_required_a = 'attr_required_a'
      lambda { @a.attr_missing! }.should_not raise_error
      lambda { @b.attr_missing! }.should raise_error(AttrRequired::AttrMissing)
      @b.attr_required_b = 'attr_required_b'
      lambda { @b.attr_missing! }.should_not raise_error
    end
  end

  describe '#attr_missing' do
    it 'should return missing attributes keys' do
      @a.attr_missing.should == [:attr_required_a]
      @b.attr_missing.should == [:attr_required_a, :attr_required_b]
      @a.attr_required_a = 'attr_required_a'
      @b.attr_required_a = 'attr_required_a'
      @a.attr_missing.should == []
      @b.attr_missing.should == [:attr_required_b]
    end
  end

  describe '.required_attributes' do
    it 'should return all required attributes keys' do
      A.required_attributes.should == [:attr_required_a]
      B.required_attributes.should == [:attr_required_a, :attr_required_b]
    end
  end

  describe '#required_attributes' do
    it 'should return required attributes keys' do
      @a.required_attributes.should == [:attr_required_a]
      @b.required_attributes.should == [:attr_required_a, :attr_required_b]
    end
  end

  describe '.undef_required_attributes' do
    it 'should undefine accessors and remove from required attributes' do
      C.required_attributes.should_not include :attr_required_a
      @c.required_attributes.should_not include :attr_required_a
      @c.should_not respond_to :attr_required_a
      @c.should_not respond_to :attr_required_a=
    end
  end
end
