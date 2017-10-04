class Status < ApplicationRecord
  belongs_to :issue

  validates :name, :issue, presence: true
end
