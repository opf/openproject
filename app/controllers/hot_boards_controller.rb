class HotBoardsController < ApplicationController
  add_flash_types :notice
  before_action :find_board, only: %i[show edit update destroy delta]


  def index
    @boards = HotBoard.all
  end

  def new
    @board = HotBoard.new
  end

  def show; end

  def edit; end

  def create
    @board = HotBoard.new board_params
    @board.save

    respond_to do |format|
      format.html { redirect_to hot_boards_path, notice: "Board was successfully created." }
    end
  end

  def update
    @board.update board_params

    respond_to do |format|
      format.html { redirect_to hot_boards_path, notice: "Board was successfully updated." }
    end
  end

  def destroy
    @board.destroy

    respond_to do |format|
      format.html { redirect_to hot_boards_path, notice: "Board was successfully destroyed." }
    end
  end

  def delta
    lists = @board.lists.pluck(:id)
    params[:delta].each do |wp, pos|
      HotItem.where(hot_list_id: lists, work_package_id: wp).update_all(position: pos)
    end
  end

  private

  def find_board
    @board = HotBoard.find(params[:id])
  end

  def board_params
    params
      .require(:hot_board)
      .permit(:title)
  end
end
