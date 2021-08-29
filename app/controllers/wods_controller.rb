class WodsController < ApplicationController
  def index
    if params.dig(:wod, :tag_list).present?
      tagged_wods = Wod.tagged_with(tag_list_params)
      @q = tagged_wods.ransack(params[:q])
    else
      @q = Wod.ransack(params[:q])
    end
    @wods = @q.result(distinct: true).order(date: :desc).page(params[:page])
    @tags = ActsAsTaggableOn::Tag.all
  end

  def show
    @wod = Wod.find(params[:id])
    @logs = @wod.logs
  end

  def edit
    @wod = Wod.find(params[:id])
    @logs = @wod.logs
    @tags = ActsAsTaggableOn::Tag.all
  end

  def update
    @wod = Wod.find(params[:id])
    @logs = @wod.logs
    @tags = ActsAsTaggableOn::Tag.all
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
      :tag_list,
    )
  end

  def tag_list_params
    params.require(:wod).permit(:tag_list)[:tag_list]
  end
end
