describe OpenProject::Boards::GridRegistration do
  let(:project) { FactoryBot.create(:project) }
  let(:permissions) { [:show_board_views] }
  let(:board) { FactoryBot.create(:board_grid, project: project) }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end

  describe '.visible' do
    context 'when having the view_boards permission' do
      it 'returns the board' do
        expect(described_class.visible(user))
          .to match_array(board)
      end
    end

    context 'when having the manage_board_views permission' do
      let(:permissions) { [:manage_board_views] }

      it 'returns the board' do
        expect(described_class.visible(user))
          .to match_array(board)
      end
    end

    context 'when having neither of the permissions' do
      let(:permissions) { [] }

      it 'returns the board' do
        expect(described_class.visible(user))
          .to be_empty
      end
    end
  end
end
