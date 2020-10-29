require 'spec_helper'
# rubocop:disable Metrics/BlockLength, Style/VariableNumber
describe Semantic::Version do
  before(:each) do
    @test_versions = [
      '1.0.0',
      '12.45.182',
      '0.0.1-pre.1',
      '1.0.1-pre.5+build.123.5',
      '1.1.1+123',
      '0.0.0+hello',
      '1.2.3-1'
    ]

    @bad_versions = [
      'a.b.c',
      '1.a.3',
      'a.3.4',
      '5.2.a',
      'pre3-1.5.3',
      "I am not a valid semver\n0.0.0\nbut I still pass"
    ]
  end

  context 'parsing' do
    it 'parses valid SemVer versions' do
      @test_versions.each do |v|
        expect { Semantic::Version.new v }.not_to raise_error
      end
    end

    it 'raises an error on invalid versions' do
      @bad_versions.each do |v|
        expect { Semantic::Version.new v }.to raise_error(
          ArgumentError,
          /not a valid SemVer/
        )
      end
    end

    it 'stores parsed versions in member variables' do
      v1 = Semantic::Version.new '1.5.9'
      expect(v1.major).to eq(1)
      expect(v1.minor).to eq(5)
      expect(v1.patch).to eq(9)
      expect(v1.pre).to be_nil
      expect(v1.build).to be_nil

      v2 = Semantic::Version.new '0.0.1-pre.1'
      expect(v2.major).to eq(0)
      expect(v2.minor).to eq(0)
      expect(v2.patch).to eq(1)
      expect(v2.pre).to eq('pre.1')
      expect(v2.build).to be_nil

      v3 = Semantic::Version.new '1.0.1-pre.5+build.123.5'
      expect(v3.major).to eq(1)
      expect(v3.minor).to eq(0)
      expect(v3.patch).to eq(1)
      expect(v3.pre).to eq('pre.5')
      expect(v3.build).to eq('build.123.5')

      v4 = Semantic::Version.new '0.0.0+hello'
      expect(v4.major).to eq(0)
      expect(v4.minor).to eq(0)
      expect(v4.patch).to eq(0)
      expect(v4.pre).to be_nil
      expect(v4.build).to eq('hello')
    end

    it 'provides round-trip fidelity for an empty build parameter' do
      v = Semantic::Version.new('1.2.3')
      v.build = ''
      expect(Semantic::Version.new(v.to_s).build).to eq(v.build)
    end

    it 'provides round-trip fidelity for a nil build parameter' do
      v = Semantic::Version.new('1.2.3+build')
      v.build = nil
      expect(Semantic::Version.new(v.to_s).build).to eq(v.build)
    end
  end

  context 'comparisons' do
    before(:each) do
      # These three are all semantically equivalent, according to the spec.
      @v1_5_9_pre_1 = Semantic::Version.new '1.5.9-pre.1'
      @v1_5_9_pre_1_build_5127 = Semantic::Version.new '1.5.9-pre.1+build.5127'
      @v1_5_9_pre_1_build_4352 = Semantic::Version.new '1.5.9-pre.1+build.4352'
      # more pre syntax testing: "-"
      @v3_13_0_75_generic = Semantic::Version.new '3.13.0-75-generic'
      @v3_13_0_141_generic = Semantic::Version.new '3.13.0-141-generic'

      @v1_5_9 = Semantic::Version.new '1.5.9'
      @v1_6_0 = Semantic::Version.new '1.6.0'

      @v1_6_0_alpha = Semantic::Version.new '1.6.0-alpha'
      @v1_6_0_alpha_1 = Semantic::Version.new '1.6.0-alpha.1'
      @v1_6_0_alpha_beta = Semantic::Version.new '1.6.0-alpha.beta'
      @v1_6_0_beta = Semantic::Version.new '1.6.0-beta'
      @v1_6_0_beta_2 = Semantic::Version.new '1.6.0-beta.2'
      @v1_6_0_beta_11 = Semantic::Version.new '1.6.0-beta.11'
      @v1_6_0_rc_1 = Semantic::Version.new '1.6.0-rc.1'

      # expected order:
      # 1.6.0-alpha < 1.6.0-alpha.1 < 1.6.0-alpha.beta < 1.6.0-beta
      # < 1.6.0-beta.2 < 1.6.0-beta.11 < 1.6.0-rc.1 < 1.6.0.
    end

    it 'determines sort order' do
      # The second parameter here can be a string, so we want to ensure that
      # this kind of comparison works also.
      expect((@v1_5_9_pre_1 <=> @v1_5_9_pre_1.to_s)).to eq(0)

      expect((@v1_5_9_pre_1 <=> @v1_5_9_pre_1_build_5127)).to eq(0)
      expect((@v1_5_9_pre_1 <=> @v1_5_9)).to eq(-1)
      expect((@v1_5_9_pre_1_build_5127 <=> @v1_5_9)).to eq(-1)

      expect(@v1_5_9_pre_1_build_5127.build).to eq('build.5127')

      expect((@v1_5_9 <=> @v1_6_0)).to eq(-1)
      expect((@v1_6_0 <=> @v1_5_9)).to eq(1)
      expect((@v1_6_0 <=> @v1_5_9_pre_1)).to eq(1)
      expect((@v1_5_9_pre_1 <=> @v1_6_0)).to eq(-1)

      expect([@v1_5_9_pre_1, @v1_5_9_pre_1_build_5127, @v1_5_9, @v1_6_0]
        .reverse.sort).to \
          eq([@v1_5_9_pre_1, @v1_5_9_pre_1_build_5127, @v1_5_9, @v1_6_0])
    end

    it 'determines sort order pre' do
      ary = [@v1_6_0_alpha, @v1_6_0_alpha_1, @v1_6_0_alpha_beta,
             @v1_6_0_beta, @v1_6_0_beta_2, @v1_6_0_beta_11, @v1_6_0_rc_1,
             @v1_6_0]
      expect(ary.shuffle.sort).to eq(ary)
    end

    it 'determine alternate char sep works in pre' do
      expect((@v3_13_0_75_generic <=> @v3_13_0_141_generic.to_s)).to eq(-1)
      expect((@v3_13_0_75_generic <=> @v3_13_0_141_generic)).to eq(-1)
      expect((@v3_13_0_75_generic <=> '3.13.0-75-generic')).to eq(0)
      expect((@v3_13_0_75_generic <=> '3.13.0-141-generic')).to eq(-1)
      expect((@v3_13_0_141_generic <=> '3.13.0-75-generic')).to eq(1)
    end

    it 'determines whether it is greater than another instance' do
      # These should be equal, since "Build metadata SHOULD be ignored
      # when determining version precedence".
      # (SemVer 2.0.0-rc.2, paragraph 10 - http://www.semver.org)
      expect(@v1_5_9_pre_1).not_to be > @v1_5_9_pre_1_build_5127
      expect(@v1_5_9_pre_1).not_to be < @v1_5_9_pre_1_build_5127

      expect(@v1_6_0).to be > @v1_5_9
      expect(@v1_5_9).not_to be > @v1_6_0
      expect(@v1_5_9).to be > @v1_5_9_pre_1_build_5127
      expect(@v1_5_9).to be > @v1_5_9_pre_1
    end

    it 'determines whether it is less than another instance' do
      expect(@v1_5_9_pre_1).not_to be < @v1_5_9_pre_1_build_5127
      expect(@v1_5_9_pre_1_build_5127).not_to be < @v1_5_9_pre_1
      expect(@v1_5_9_pre_1).to be < @v1_5_9
      expect(@v1_5_9_pre_1).to be < @v1_6_0
      expect(@v1_5_9_pre_1_build_5127).to be < @v1_6_0
      expect(@v1_5_9).to be < @v1_6_0
    end

    it 'determines whether it is greater than or equal to another instance' do
      expect(@v1_5_9_pre_1).to be >= @v1_5_9_pre_1
      expect(@v1_5_9_pre_1).to be >= @v1_5_9_pre_1_build_5127
      expect(@v1_5_9_pre_1_build_5127).to be >= @v1_5_9_pre_1
      expect(@v1_5_9).to be >= @v1_5_9_pre_1
      expect(@v1_6_0).to be >= @v1_5_9
      expect(@v1_5_9_pre_1_build_5127).not_to be >= @v1_6_0
    end

    it 'determines whether it is less than or equal to another instance' do
      expect(@v1_5_9_pre_1).to be <= @v1_5_9_pre_1_build_5127
      expect(@v1_6_0).not_to be <= @v1_5_9
      expect(@v1_5_9_pre_1_build_5127).to be <= @v1_5_9_pre_1_build_5127
      expect(@v1_5_9).not_to be <= @v1_5_9_pre_1
    end

    it 'determines whether it is semantically equal to another instance' do
      expect(@v1_5_9_pre_1).to eq(@v1_5_9_pre_1.dup)
      expect(@v1_5_9_pre_1_build_5127).to eq(@v1_5_9_pre_1_build_5127.dup)

      # "Semantically equal" is the keyword here; these are by definition
      # not "equal" (different build), but should be treated as
      # equal according to the spec.
      expect(@v1_5_9_pre_1_build_4352).to eq(@v1_5_9_pre_1_build_5127)
      expect(@v1_5_9_pre_1_build_4352).to eq(@v1_5_9_pre_1)
    end

    it 'determines whether it is between two others instance' do
      expect(@v1_5_9).to be_between @v1_5_9_pre_1, @v1_6_0
      expect(@v1_5_9).to_not be_between @v1_6_0, @v1_6_0_beta
    end

    it 'determines whether it satisfies >= style specifications' do
      expect(@v1_6_0.satisfies?('>=1.6.0')).to be true
      expect(@v1_6_0.satisfies?('<=1.6.0')).to be true
      expect(@v1_6_0.satisfies?('>=1.5.0')).to be true
      expect(@v1_6_0.satisfies?('<=1.5.0')).not_to be true

      # partial / non-semver numbers after comparator are extremely common in
      # version specifications in the wild

      expect(@v1_6_0.satisfies?('>1.5')).to be true
      expect(@v1_6_0.satisfies?('<1')).not_to be true
    end

    it 'determines whether it satisfies * style specifications' do
      expect(@v1_6_0.satisfies?('1.*')).to be true
      expect(@v1_6_0.satisfies?('1.6.*')).to be true
      expect(@v1_6_0.satisfies?('2.*')).not_to be true
      expect(@v1_6_0.satisfies?('1.5.*')).not_to be true
    end

    it 'determines whether it satisfies ~ style specifications' do
      expect(@v1_6_0.satisfies?('~1.6')).to be true
      expect(@v1_5_9_pre_1.satisfies?('~1.5')).to be true
      expect(@v1_6_0.satisfies?('~1.5')).not_to be true
    end

    it 'determines whether it satisfies ~> style specifications' do
      expect(@v1_5_9_pre_1_build_5127.satisfies?('~> 1.4')).to be true
      expect(@v1_5_9_pre_1_build_4352.satisfies?('~> 1.5.2')).to be true
      expect(@v1_6_0_alpha_1.satisfies?('~> 1.4')).to be true

      expect(@v1_5_9.satisfies?('~> 1.0')).to be true
      expect(@v1_5_9.satisfies?('~> 1.4')).to be true
      expect(Semantic::Version.new('1.99.1').satisfies?('~> 1.5')).to be true
      expect(@v1_5_9.satisfies?('~> 1.5')).to be true
      expect(@v1_5_9.satisfies?('~> 1.5.0')).to be true
      expect(@v1_5_9.satisfies?('~> 1.5.8')).to be true
      expect(@v1_5_9.satisfies?('~> 1.5.9')).to be true
      expect(Semantic::Version.new('1.5.99').satisfies?('~> 1.5.9')).to be true
      expect(@v1_5_9.satisfies?('~> 1.6.0')).to be false
      expect(@v1_5_9.satisfies?('~> 1.6')).to be false
      expect(@v1_5_9.satisfies?('~> 1.7')).to be false
    end

    it 'determines whether version is satisfies by range of bound versions' do
      v5_2_1 = Semantic::Version.new('5.2.1')
      v5_3_0 = Semantic::Version.new('5.3.0')
      v6_0_1 = Semantic::Version.new('6.0.1')
      range = [
        ">= 5.2.1",
        "<= 6.0.0"
      ]

      expect(v5_2_1.satisfied_by?(range)).to be true
      expect(v5_3_0.satisfied_by?(range)).to be true
      expect(v6_0_1.satisfied_by?(range)).to be false
    end

    it 'raises error if the input is not an array of versions' do
      v5_2_1 = Semantic::Version.new('5.2.1')
      range = ">= 5.2.1 <= 6.0.0"
      expect { v5_2_1.satisfied_by?(range) }.to raise_error(
        ArgumentError,
        /should be an array of versions/
      )
    end
  end

  context 'type coercions' do
    it 'converts to a string' do
      @test_versions.each do |v|
        expect(Semantic::Version.new(v).to_s).to be == v
      end
    end

    it 'converts to an array' do
      expect(Semantic::Version.new('1.0.0').to_a).to \
        eq([1, 0, 0, nil, nil])
      expect(Semantic::Version.new('6.1.4-pre.5').to_a).to \
        eq([6, 1, 4, 'pre.5', nil])
      expect(Semantic::Version.new('91.6.0+build.17').to_a).to \
        eq([91, 6, 0, nil, 'build.17'])
      expect(Semantic::Version.new('0.1.5-pre.7+build191').to_a).to \
        eq([0, 1, 5, 'pre.7', 'build191'])
    end

    it 'converts to a hash' do
      expect(Semantic::Version.new('1.0.0').to_h).to \
        eq(major: 1, minor: 0, patch: 0, pre: nil, build: nil)
      expect(Semantic::Version.new('6.1.4-pre.5').to_h).to \
        eq(major: 6, minor: 1, patch: 4, pre: 'pre.5', build: nil)
      expect(Semantic::Version.new('91.6.0+build.17').to_h).to \
        eq(major: 91, minor: 6, patch: 0, pre: nil, build: 'build.17')
      expect(Semantic::Version.new('0.1.5-pre.7+build191').to_h).to \
        eq(major: 0, minor: 1, patch: 5, pre: 'pre.7', build: 'build191')
    end

    it 'aliases conversion methods' do
      v = Semantic::Version.new('0.0.0')
      [:to_hash, :to_array, :to_string].each do |sym|
        expect(v).to respond_to(sym)
      end
    end
  end

  it 'as hash key' do
    hash = {}
    hash[Semantic::Version.new('1.2.3-pre1+build2')] = 'semantic'
    expect(hash[Semantic::Version.new('1.2.3-pre1+build2')]).to eq('semantic')
  end

  describe '#major!' do
    subject { described_class.new('1.2.3-pre1+build2') }

    context 'changing the major term' do
      it 'changes the major version and resets the others' do
        expect(subject.major!).to eq('2.0.0')
      end
    end
  end

  describe '#minor!' do
    subject { described_class.new('1.2.3-pre1+build2') }

    context 'changing the minor term' do
      it 'changes minor term and resets patch, pre and build' do
        expect(subject.minor!).to eq('1.3.0')
      end
    end
  end

  describe '#patch!' do
    subject { described_class.new('1.2.3-pre1+build2') }

    context 'changing the patch term' do
      it 'changes the patch term and resets the pre and build' do
        expect(subject.patch!).to eq('1.2.4')
      end
    end
  end

  describe '#increment!' do
    subject { described_class.new('1.2.3-pre1+build2') }

    context 'changing the minor term' do
      context 'with a string' do
        it 'changes the minor term and resets the path, pre and build' do
          expect(subject.increment!('minor')).to eq('1.3.0')
        end
      end

      context 'with a symbol' do
        it 'changes the minor term and resets the path, pre and build' do
          expect(subject.increment!(:minor)).to eq('1.3.0')
        end
      end
    end
  end
end
