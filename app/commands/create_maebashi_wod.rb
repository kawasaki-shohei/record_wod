require 'net/http'

class CreateMaebashiWod

  prepend SimpleCommand
  include ActiveModel::Model
  include ActiveModel::Attributes

  WOD_URL = Rails.application.credentials.dig(:maebashi, :url)
  WOD_CONTENT_CLASS_NAME = Rails.application.credentials.dig(:maebashi, :wod_content_class_name)
  AD_ID_NAME = Rails.application.credentials.dig(:maebashi, :ad_id_name)

  attribute :target_date, :date, default: Date.current

  validate :must_be_correct_date

  def initialize(*)
    super
    @logger = Rails.logger
  end

  def call
    return nil if invalid?

    call_init_wod
    wod_url = fetch_wod_url
    return nil if wod_url.nil?

    set_wod_data(wod_url)
    return nil if errors.any?

    @wod.save!
    output_success_log
    @wod
  end

  private

  def must_be_correct_date
    errors.add(:target_date, :invalid) unless target_date.is_a?(Date)
    # MARK: CrossfitMaebashiに同じ日のWODは存在しない
    errors.add(:target_date, "が重複しています。") if Wod.exists?(date: target_date, box: :maebashi)
  end

  def call_init_wod
    @wod = Wod.new(box: :maebashi)
  end

  def output_request_log(uri)
    @logger.info(<<~LOG)
      =================================
      CrossFitMaebashiへ通信開始
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
      #{@wod.date}のCrossFitMaebashiのWODの取得に成功しました。
      =================================
    LOG
  end

  def fetch_html(url_str)
    uri = URI.parse(URI.encode(url_str))
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

  def fetch_wod_url
    uri = "#{WOD_URL}category/wod/"
    response = fetch_html(uri)
    if response.code_type == Net::HTTPOK
      @logger.info("WOD一覧の取得に成功")
      doc = Nokogiri::HTML.parse(response.body)
      entry_title = doc.css(".entry-title").first
      entry_a_tag = entry_title.css("a").first
      entry_a_tag.attribute('href').value
    elsif response.code_type == Net::HTTPNotFound
      message = "WOD一覧画面は存在しません。"
      errors.add(:base, message)
      @logger.info(message)
      return nil
    else
      raise "Unexpected Error"
    end
  end

  def set_wod_data(url)
    response = fetch_html(url)
    if response.code_type == Net::HTTPOK
      @logger.info("#{target_date}のWODの取得に成功")
      doc = Nokogiri::HTML.parse(response.body)
      entry_content = doc.css(".#{WOD_CONTENT_CLASS_NAME}").first
      entry_content.css("##{AD_ID_NAME}").remove
      @wod.date = target_date
      @wod.name = "Maebashi#{target_date.to_s}"
      # MARK: textを呼び出すとbrタグの改行が消えてしまうため予め改行コードに変換しておく
      entry_content.search('br').each { |br| br.replace("\n") }
      @wod.content = entry_content.text.strip.gsub(/\n+/, "\n")
    elsif response.code_type == Net::HTTPNotFound
      message = "#{target_date}のWODは存在しません。"
      errors.add(:base, message)
      @logger.info(message)
    else
      raise "Unexpected Error"
    end
  end

end
