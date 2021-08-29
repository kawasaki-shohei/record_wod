module ApplicationHelper

  def wod_params_hash
    return nil if params[:q].blank?

    params.require(:q).permit(:date_eq, :content_i_cont).to_hash
  end

  def tag_list_params_hash
    return nil if params[:wod].blank?

    params.require(:wod).permit(:tag_list).to_hash
  end

end
