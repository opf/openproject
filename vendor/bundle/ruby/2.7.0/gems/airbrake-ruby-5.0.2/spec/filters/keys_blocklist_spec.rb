RSpec.describe Airbrake::Filters::KeysBlocklist do
  subject { described_class.new(patterns) }

  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  shared_examples 'pattern matching' do |patts, params|
    let(:patterns) { patts }

    it "filters out the matching values" do
      notice[:params] = params.first
      subject.call(notice)
      expect(notice[:params]).to eq(params.last)
    end
  end

  context "when a pattern is a Regexp" do
    include_examples(
      'pattern matching',
      [/\Abon/],
      [
        { bongo: 'bango' },
        { bongo: '[Filtered]' },
      ],
    )

    context "and when a key is a hash" do
      let(:patterns) { [/bango/] }

      # https://github.com/airbrake/airbrake/issues/739
      it "doesn't fail" do
        notice[:params] = { bingo: { {} => 'unfiltered' } }
        expect { subject.call(notice) }.not_to raise_error
      end
    end
  end

  context "when a pattern is a Symbol" do
    include_examples(
      'pattern matching',
      [:bingo],
      [
        { bingo: 'bango' },
        { bingo: '[Filtered]' },
      ],
    )
  end

  context "when a pattern is a String" do
    include_examples(
      'pattern matching',
      ['bingo'],
      [
        { bingo: 'bango' },
        { bingo: '[Filtered]' },
      ],
    )
  end

  context "when a pattern is a Array of Hash" do
    include_examples(
      'pattern matching',
      ['bingo'],
      [
        { array: [{ bingo: 'bango' }, []] },
        { array: [{ bingo: '[Filtered]' }, []] },
      ],
    )
  end

  context "when a Proc pattern was provided" do
    context "along with normal keys" do
      include_examples(
        'pattern matching',
        [proc { 'bongo' }, :bash],
        [
          { bingo: 'bango', bongo: 'bish', bash: 'bosh' },
          { bingo: 'bango', bongo: '[Filtered]', bash: '[Filtered]' },
        ],
      )
    end

    context "which doesn't return an array of keys" do
      include_examples(
        'pattern matching',
        [proc { Object.new }],
        [
          { bingo: 'bango', bongo: 'bish' },
          { bingo: 'bango', bongo: 'bish' },
        ],
      )

      it "logs an error" do
        expect(Airbrake::Loggable.instance).to receive(:error).with(
          /KeysBlocklist is invalid.+patterns: \[#<Object:.+>\]/,
        )
        keys_blocklist = described_class.new(patterns)
        keys_blocklist.call(notice)
      end
    end

    context "which returns another Proc" do
      let(:patterns) { [proc { proc { ['bingo'] } }] }

      context "and when the filter is called once" do
        it "logs an error" do
          expect(Airbrake::Loggable.instance).to receive(:error).with(
            /KeysBlocklist is invalid.+patterns: \[#<Proc:.+>\]/,
          )
          keys_blocklist = described_class.new(patterns)
          keys_blocklist.call(notice)
        end
      end

      context "and when the filter is called twice" do
        it "unwinds procs and filters keys" do
          notice[:params] = { bingo: 'bango', bongo: 'bish' }
          2.times { subject.call(notice) }
          expect(notice[:params]).to eq(bingo: '[Filtered]', bongo: 'bish')
        end
      end
    end
  end

  context "when a pattern is invalid" do
    include_examples(
      'pattern matching',
      [Object.new],
      [
        { bingo: 'bango', bongo: 'bish' },
        { bingo: 'bango', bongo: 'bish' },
      ],
    )

    it "logs an error" do
      expect(Airbrake::Loggable.instance).to receive(:error).with(
        /KeysBlocklist is invalid.+patterns: \[#<Object:.+>\]/,
      )
      keys_blocklist = described_class.new(patterns)
      keys_blocklist.call(notice)
    end
  end

  context "when a value contains a nested hash" do
    context "and it is non-recursive" do
      include_examples(
        'pattern matching',
        ['bish'],
        [
          { bongo: { bish: 'bash' } },
          { bongo: { bish: '[Filtered]' } },
        ],
      )

      it "doesn't mutate the original hash" do
        params = { bongo: { bish: 'bash' } }
        notice[:params] = params

        blocklist = described_class.new([:bish])
        blocklist.call(notice)

        expect(params[:bongo][:bish]).to eq('bash')
      end
    end

    context "and it is recursive" do
      bongo = { bingo: {} }
      bongo[:bingo][:bango] = bongo

      include_examples(
        'pattern matching',
        ['bango'],
        [
          bongo,
          { bingo: { bango: '[Filtered]' } },
        ],
      )
    end
  end

  describe "context payload" do
    context "when a URL with query params is present" do
      let(:patterns) { ['bish'] }

      it "filters the params" do
        notice[:context][:url] =
          'http://localhost:3000/crash?foo=bar&baz=bongo&bish=bash&color=%23FFAAFF'

        subject.call(notice)
        expect(notice[:context][:url]).to(
          eq('http://localhost:3000/crash?foo=bar&baz=bongo&bish=[Filtered]&color=%23FFAAFF'),
        )
      end
    end

    context "when the user key is present" do
      let(:patterns) { ['user'] }

      it "filters out the user" do
        notice[:context][:user] = { id: 1337, name: 'Bingo Bango' }
        subject.call(notice)
        expect(notice[:context][:user]).to eq('[Filtered]')
      end
    end

    context "and when it is a hash" do
      let(:patterns) { ['name'] }

      it "filters out individual user fields" do
        notice[:context][:user] = { id: 1337, name: 'Bingo Bango' }
        subject.call(notice)
        expect(notice[:context][:user][:name]).to eq('[Filtered]')
      end
    end
  end

  context "when the headers key is present" do
    let(:patterns) { ['headers'] }

    it "filters out the headers" do
      notice[:context][:headers] = { 'HTTP_COOKIE' => 'banana' }
      subject.call(notice)
      expect(notice[:context][:headers]).to eq('[Filtered]')
    end

    context "and when it is a hash" do
      let(:patterns) { ['HTTP_COOKIE'] }

      it "filters out individual header fields" do
        notice[:context][:headers] = { 'HTTP_COOKIE' => 'banana' }
        subject.call(notice)
        expect(notice[:context][:headers]['HTTP_COOKIE']).to eq('[Filtered]')
      end
    end
  end
end
