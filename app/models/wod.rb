class Wod < ApplicationRecord

  attr_accessor :specified_date

  has_many :logs

  enum box: { none: 0, roppongi: 1, maebashi: 2 }, _prefix: :box

  validates :date, presence: true
  validates :name, presence: true
  validates :content, presence: true
  validate :must_be_same_date_as_specified_date, if: :specified_date

  def create_from_html(html)
    attributes = WodExtraction.execute(html)
    if attributes.present?
      assign_attributes(attributes)
      save
    else
      true  # WODがない時はtrueで返してスキップする
    end
  end

  private

  def must_be_same_date_as_specified_date
    if date != specified_date
      errors[:base] << "指定したWodの日付と異なっています。"
    end
  end

  class WodExtraction
    WOD_DATE_ID = Rails.application.credentials.dig(:wodify, :html, :wod_date_id)
    NO_WOD_FOUND_TEXT = Rails.application.credentials.dig(:wodify, :html, :no_wod_found_text)
    ANNOUNCEMENT_ID = Rails.application.credentials.dig(:wodify, :html, :wod_announcement_id)
    MAIN_CONTENT_ID = Rails.application.credentials.dig(:wodify, :html, :wod_main_content_id)

    def self.execute(html)
      attributes = {}
      doc = Nokogiri::HTML.parse(html)
      displayed_date_str = doc.css("##{WOD_DATE_ID}").text
      Rails.logger.info("displayed_date_str: #{displayed_date_str}")
      if displayed_date_str == NO_WOD_FOUND_TEXT
        Rails.logger.info("Skipped this date because of no wod")
        return false
      end
      attributes[:date] = Date.parse(displayed_date_str)
      doc.css("##{ANNOUNCEMENT_ID}").remove
      attributes[:content] = doc.css("##{MAIN_CONTENT_ID}").inner_html.gsub(/\n/, "")
      attributes
    end
  end
end
