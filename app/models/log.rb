class Log < ApplicationRecord
  enum kind: {
    unset: 0,
    wod: 1,
    skill: 2,
    strength: 3,
    conditioning: 4,
    stretch: 5,
    other: 99
  }

  belongs_to :wod

  validates :date, presence: true
  validates :rate, numericality: { greater_than_or_equal_to: 0.5, less_than_or_equal_to: 5.0 }
end
