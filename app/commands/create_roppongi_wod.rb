require 'net/http'

class CreateRoppongiWod

  prepend SimpleCommand
  include ActiveModel::Model
  include ActiveModel::Attributes

  WOD_URL = Rails.application.credentials.dig(:roppongi, :url)
  WOD_CONTENT_CLASS_NAME = Rails.application.credentials.dig(:roppongi, :wod_content_class_name)

  validate :must_be_correct_date

  def initialize(*)
    super
    @logger = Rails.logger
  end

  def call
    # return nil if invalid?

    call_init_wod
    set_wod_data(fetch_wod)
    return nil if errors.any?
    return nil if invalid?

    @wod.save!
    output_success_log
    @wod
  end

  private

  def must_be_correct_date
    # MARK: CrossfitRoppongiに同じ日のWODは存在しない
    errors.add(:base, "日付が重複しています。") if Wod.exists?(date: @wod.date, box: :roppongi)
  end

  def call_init_wod
    @wod = Wod.new(box: :roppongi)
  end

  def output_request_log(uri)
    @logger.info(<<~LOG)
      =================================
      CrossFitRoppongiへ通信開始
      URI: #{uri}
      =================================
    LOG
  end

  def output_response_log(response)
    @logger.info(<<~LOG)
      =================================
      通信終了
      response.code: #{response.code}
      =================================
    LOG
  end

  def output_success_log
    @logger.info(<<~LOG)
      =================================
      #{@wod.date}のCrossFitRoppongiのWODの取得に成功しました。
      =================================
    LOG
  end

  def fetch_wod
    # target_date_str = target_date.strftime('%Y-%-m-%-d')
    # prev_date_str = target_date.prev_day.strftime('%Y/%m/%d')
    uri = URI.parse(URI.encode(WOD_URL))
    http = Net::HTTP.new(uri.host, uri.port)

    # 通信設定
    http.use_ssl = true if uri.scheme == 'https'
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.read_timeout = 100
    http.open_timeout = 100

    # 送信内容設定
    req = Net::HTTP::Get.new(uri.request_uri)
    headers = { "Content-Type" => "application/json; charset=utf8" }
    req.initialize_http_header(headers)

    output_request_log(uri)

    # 送信
    begin
      response = http.request(req)
    rescue => e
      logger.error("#{self.class.name}.#{method_name} : #{[uri, e.class, e].join(" : ")}")
      return
    end

    output_response_log(response)
    response
  end

  def set_wod_data(response)
    if response.code_type == Net::HTTPOK
      @logger.info("CrossFitRoppongiのWODの取得に成功")
      doc = Nokogiri::HTML.parse(response.body)
      year = doc.css('.date .year').first.text
      month = doc.css('.date .month').first.text.delete('月')
      day = doc.css('.date .day').first.text
      target_date = Date.parse("#{year}-#{month}-#{day}")
      article_content_wrap = doc.css(".#{WOD_CONTENT_CLASS_NAME}").first
      # MARK: textを呼び出すとbrタグの改行が消えてしまうため予め改行コードに変換しておく
      article_content_wrap.search('br').each { |br| br.replace("\n") }
      @wod.content = article_content_wrap.text.strip.gsub(/\r\n+|\n+|\r+/, "\n")
      @wod.date = target_date
      @wod.name = "Roppongi#{target_date.to_s}"
    elsif response.code_type == Net::HTTPNotFound
      message = "WODページにアクセスできません"
      errors.add(:base, message)
      @logger.info(message)
    else
      raise "Unexpected Error"
    end
  end
end
