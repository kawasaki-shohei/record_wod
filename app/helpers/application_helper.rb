module ApplicationHelper

  def wod_params_hash
    return nil if params[:q].blank?

    params.require(:q).permit(:date_eq, :content_i_cont).to_hash
  end

end
