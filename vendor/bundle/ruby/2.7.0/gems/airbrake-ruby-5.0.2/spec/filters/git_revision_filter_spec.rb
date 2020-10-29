RSpec.describe Airbrake::Filters::GitRevisionFilter do
  subject { described_class.new('root/dir') }

  # 'let!', not 'let' to make sure Notice doesn't call File.exist? with
  # unexpected arguments.
  let!(:notice) { Airbrake::Notice.new(AirbrakeTestError.new) }

  context "when context/revision is defined" do
    it "doesn't attach anything to context/revision" do
      notice[:context][:revision] = '1.2.3'
      subject.call(notice)
      expect(notice[:context][:revision]).to eq('1.2.3')
    end
  end

  context "when .git directory doesn't exist" do
    it "doesn't attach anything to context/revision" do
      subject.call(notice)
      expect(notice[:context][:revision]).to be_nil
    end
  end

  context "when .git directory exists" do
    before do
      expect(File).to receive(:exist?).with('root/dir/.git').and_return(true)
    end

    context "and when HEAD doesn't exist" do
      before do
        expect(File).to receive(:exist?).with('root/dir/.git/HEAD').and_return(false)
      end

      it "doesn't attach anything to context/revision" do
        subject.call(notice)
        expect(notice[:context][:revision]).to be_nil
      end
    end

    context "and when HEAD exists" do
      before do
        expect(File).to receive(:exist?).with('root/dir/.git/HEAD').and_return(true)
      end

      context "and also when HEAD doesn't start with 'ref: '" do
        before do
          expect(File).to(
            receive(:read).with('root/dir/.git/HEAD').and_return('refs/foo'),
          )
        end

        it "attaches the content of HEAD to context/revision" do
          subject.call(notice)
          expect(notice[:context][:revision]).to eq('refs/foo')
        end
      end

      context "and also when HEAD starts with 'ref: " do
        before do
          expect(File).to(
            receive(:read).with('root/dir/.git/HEAD').and_return("ref: refs/foo\n"),
          )
        end

        context "when the ref exists" do
          before do
            expect(File).to(
              receive(:exist?).with('root/dir/.git/refs/foo').and_return(true),
            )
            expect(File).to(
              receive(:read).with('root/dir/.git/refs/foo').and_return("d34db33f\n"),
            )
          end

          it "attaches the revision from the ref to context/revision" do
            subject.call(notice)
            expect(notice[:context][:revision]).to eq('d34db33f')
          end
        end

        context "when the ref doesn't exist" do
          before do
            expect(File).to(
              receive(:exist?).with('root/dir/.git/refs/foo').and_return(false),
            )
          end

          context "and when '.git/packed-refs' exists" do
            before do
              expect(File).to(
                receive(:exist?).with('root/dir/.git/packed-refs').and_return(true),
              )
              expect(File).to(
                receive(:readlines).with('root/dir/.git/packed-refs').and_return(
                  [
                    "# pack-refs with: peeled fully-peeled\n",
                    "ccb316eecff79c7528d1ad43e5fa165f7a44d52e refs/tags/v3.0.30\n",
                    "^d358900f73ee5bfd6ca3a592cf23ac6e82df83c1",
                    "d34db33f refs/foo\n",
                  ],
                ),
              )
            end

            it "attaches the revision from 'packed-refs' to context/revision" do
              subject.call(notice)
              expect(notice[:context][:revision]).to eq('d34db33f')
            end
          end

          context "and when '.git/packed-refs' doesn't exist" do
            before do
              expect(File).to(
                receive(:exist?).with('root/dir/.git/packed-refs').and_return(false),
              )
            end

            it "attaches the content of HEAD to context/revision" do
              subject.call(notice)
              expect(notice[:context][:revision]).to eq('refs/foo')
            end
          end
        end
      end
    end
  end
end
