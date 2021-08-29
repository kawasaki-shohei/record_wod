class WodsController < ApplicationController
  def index
    @q = Wod.ransack(params[:q])
    @wods = @q.result(distinct: true).order(date: :desc).page(params[:page])
  end

  def show
    @wod = Wod.find(params[:id])
    @logs = @wod.logs
  end

  def edit
    @wod = Wod.find(params[:id])
    @logs = @wod.logs
  end

  def update
    @wod = Wod.find(params[:id])
    if @wod.update(wod_params)
      redirect_to wod_path(@wod), notice: '更新しました。'
    else
      render :edit
    end
  end

  private

  def wod_params
    params.require(:wod).permit(
      :date,
      :name,
      :content,
      :box,
    )
  end
end
