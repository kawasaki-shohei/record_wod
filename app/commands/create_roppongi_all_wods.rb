require 'net/http'

class CreateRoppongiAllWods
  prepend SimpleCommand
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :create_roppongi_wod_command, default: CreateRoppongiWod

  FIRST_PAGE = 200
  LAST_PAGE = 2

  def initialize(*)
    super
    @logger = Rails.logger
  end

  def call
    failed_page = []
    FIRST_PAGE.downto(LAST_PAGE) do |page_number|
      command = create_roppongi_wod_command.call(page: page_number)
      if command.failure?
        @logger.warn("Page: #{page_number}でエラーがありました。")
        @logger.warn(command.errors.full_messages)
        failed_page << page_number
      end
      sleep(1)
    end

    if failed_page.any?
      @logger.warn("登録できなかったページ: #{failed_page}")
    end
  end

end
