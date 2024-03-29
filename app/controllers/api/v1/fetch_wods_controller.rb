class Api::V1::FetchWodsController < ActionController::API
  def create
    command = CreateRoppongiWod.call
    if command.success?
      message = "#{command.result.date}のWODの登録が完了しました。"
    else
      message = "#{Date.current}のWODの登録に失敗しました。\n#{command.errors.full_messages.to_sentence}\n"
    end
    render plain: message, status: 200
  end
end
