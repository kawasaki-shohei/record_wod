class LogsController < ApplicationController
  def index
    @logs = Log.eager_load(:wod).where(date: params[:start]..params[:end])
  end

  def new
    @wod = Wod.find(params[:wod_id])
    @log = Log.new
  end

  def create
    @wod = Wod.find(params[:wod_id])
    @log = @wod.logs.build(log_params)
    if @log.save
      redirect_to wod_log_path(@wod, @log), notice: "ログを追加しました。"
    else
      render :new
    end
  end

  def show
    @wod = Wod.find(params[:wod_id])
    @log = @wod.logs.find(params[:id])
  end

  def edit
    @wod = Wod.find(params[:wod_id])
    @log = @wod.logs.find(params[:id])
  end

  def update
    @wod = Wod.find(params[:wod_id])
    @log = @wod.logs.find(params[:id])
    if @log.update(log_params)
      redirect_to wod_log_path(@wod, @log), notice: "ログを更新しました。"
    else
      render :edit
    end
  end

  def destroy
    @wod = Wod.find(params[:wod_id])
    @log = @wod.logs.find(params[:id])
    @log.destroy
    redirect_to wod_path(@wod), notice: "ログを削除しました。"
  end

  private

  def log_params
    params.require(:log).permit(:date, :kind, :result, :memo, :rate)
  end
end
