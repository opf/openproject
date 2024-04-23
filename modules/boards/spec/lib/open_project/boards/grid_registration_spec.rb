require "spec_helper"

RSpec.describe OpenProject::Boards::GridRegistration do
  let(:project) { create(:project) }
  let(:permissions) { [:show_board_views] }
  let(:board) { create(:board_grid, project:) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  describe "from_scope" do
    subject { described_class.from_scope "/foobar/projects/bla/boards" }

    context "with a relative URL root", with_config: { rails_relative_url_root: "/foobar" } do
      it "maps that correctly" do
        expect(subject).to be_present
        expect(subject[:class]).to eq(Boards::Grid)
      end
    end
  end

  describe ".visible" do
    context "when having the view_boards permission" do
      it "returns the board" do
        expect(described_class.visible(user))
          .to match_array(board)
      end
    end

    context "when having the manage_board_views permission" do
      let(:permissions) { [:manage_board_views] }

      it "returns the board" do
        expect(described_class.visible(user))
          .to match_array(board)
      end
    end

    context "when having neither of the permissions" do
      let(:permissions) { [] }

      it "returns the board" do
        expect(described_class.visible(user))
          .to be_empty
      end
    end
  end
end
