RSpec.describe Airbrake::Filters::ThreadFilter do
  let(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  def new_thread
    Thread.new do
      th = Thread.current

      # Ensure a thread always has some variable to make sure the
      # :fiber_variables Hash is always present.
      th[:random_var] = 42
      yield(th)
    end.join
  end

  describe "thread variables" do
    shared_examples "expected thread variable" do |var|
      it "attaches the thread variable" do
        new_thread do |th|
          th.thread_variable_set(:bingo, var)
          subject.call(notice)
        end

        expect(notice[:params][:thread][:thread_variables][:bingo]).to eq(var)
      end
    end

    context "given nil" do
      include_examples "expected thread variable", nil
    end

    context "given true" do
      include_examples "expected thread variable", true
    end

    context "given false" do
      include_examples "expected thread variable", false
    end

    context "given a String" do
      include_examples "expected thread variable", 'bango'
    end

    context "given a Symbol" do
      include_examples "expected thread variable", :bango
    end

    context "given a Regexp" do
      include_examples "expected thread variable", /bango/
    end

    context "given an Integer" do
      include_examples "expected thread variable", 1
    end

    context "given a Float" do
      include_examples "expected thread variable", 1.01
    end

    context "given an Object" do
      it "converts it to a String and attaches" do
        new_thread do |th|
          th.thread_variable_set(:bingo, Object.new)
          subject.call(notice)
        end

        vars = notice[:params][:thread][:thread_variables]
        expect(vars[:bingo]).to match(/\A#<Object:.+>\z/)
      end
    end

    context "given an Array of nested Hashes with complex objects" do
      let(:var) do
        [
          {
            bango: {
              bongo: [
                {
                  bish: {
                    bash: 'foo',
                    bosh: Object.new,
                  },
                },
              ],
            },
          },
          123,
        ]
      end

      it "converts objects to a safe objects" do
        new_thread do |th|
          th.thread_variable_set(:bingo, var)
          subject.call(notice)
        end

        vars = notice[:params][:thread][:thread_variables]
        expect(vars[:bingo]).to(
          match(
            [
              {
                bango: {
                  bongo: [
                    {
                      bish: {
                        bash: 'foo',
                        bosh: /\A#<Object:.+>\z/,
                      },
                    },
                  ],
                },
              },
              123,
            ],
          ),
        )
      end
    end

    it "ignores thread variables starting with an underscore" do
      var = :__recursive_key__

      new_thread do |th|
        th.thread_variable_set(var, :bingo)
        subject.call(notice)
      end

      thread_variables = notice[:params][:thread][:thread_variables]
      expect(thread_variables).to be_nil
    end
  end

  describe "fiber variables" do
    shared_examples "expected fiber variable" do |var|
      it "attaches the fiber variable" do
        new_thread do |th|
          th[:bingo] = var
          subject.call(notice)
        end

        expect(notice[:params][:thread][:fiber_variables][:bingo]).to eq(var)
      end
    end

    context "given nil" do
      include_examples "expected fiber variable", nil
    end

    context "given true" do
      include_examples "expected fiber variable", true
    end

    context "given false" do
      include_examples "expected fiber variable", false
    end

    context "given a String" do
      include_examples "expected fiber variable", 'bango'
    end

    context "given a Symbol" do
      include_examples "expected fiber variable", :bango
    end

    context "given a Regexp" do
      include_examples "expected fiber variable", /bango/
    end

    context "given an Integer" do
      include_examples "expected fiber variable", 1
    end

    context "given a Float" do
      include_examples "expected fiber variable", 1.01
    end

    context "given an Object" do
      it "converts it to a String and attaches" do
        new_thread do |th|
          th[:bingo] = Object.new
          subject.call(notice)
        end

        vars = notice[:params][:thread][:fiber_variables]
        expect(vars[:bingo]).to match(/\A#<Object:.+>\z/)
      end
    end

    context "given an Array of nested Hashes with complex objects" do
      let(:var) do
        [
          {
            bango: {
              bongo: [
                {
                  bish: {
                    bash: 'foo',
                    bosh: Object.new,
                  },
                },
              ],
            },
          },
          123,
        ]
      end

      it "converts objects to a safe objects" do
        new_thread do |th|
          th[:bingo] = var
          subject.call(notice)
        end

        vars = notice[:params][:thread][:fiber_variables]
        expect(vars[:bingo]).to(
          match(
            [
              {
                bango: {
                  bongo: [
                    {
                      bish: {
                        bash: 'foo',
                        bosh: /\A#<Object:.+>\z/,
                      },
                    },
                  ],
                },
              },
              123,
            ],
          ),
        )
      end
    end
  end

  it "appends name", skip: !Thread.current.respond_to?(:name) do
    new_thread do |th|
      th.name = 'bingo'
      subject.call(notice)
    end

    expect(notice[:params][:thread][:name]).to eq('bingo')
  end

  it "appends thread inspect (self)" do
    subject.call(notice)
    expect(notice[:params][:thread][:self]).to match(/\A#<Thread:.+>\z/)
  end

  it "appends thread group" do
    subject.call(notice)
    expect(notice[:params][:thread][:group][0]).to match(/\A#<Thread:.+>\z/)
  end

  it "appends priority" do
    subject.call(notice)
    expect(notice[:params][:thread][:priority]).to eq(0)
  end

  it "appends safe_level", skip: (
    "Not supported on this version of Ruby." unless Airbrake::HAS_SAFE_LEVEL
  ) do
    subject.call(notice)
    expect(notice[:params][:thread][:safe_level]).to eq(0)
  end

  it "ignores fiber variables starting with an underscore" do
    key = :__recursive_key__

    new_thread do |th|
      th[key] = :bingo
      subject.call(notice)
    end

    fiber_variables = notice[:params][:thread][:fiber_variables]
    expect(fiber_variables[key]).to be_nil
  end
end
