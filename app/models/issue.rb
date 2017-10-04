class Issue < ApplicationRecord
  STATUSES = %w[pending in_progress resolved].freeze

  belongs_to :author, class_name: 'User', inverse_of: :issues
  belongs_to :assignee, class_name: 'User', inverse_of: :assigned_issues

  has_many :statuses, dependent: :destroy

  validates :title, :status, :author, presence: true
  validates :status, inclusion: {in: STATUSES}

  after_save :save_status

  private

  def save_status
    return unless saved_changes.include?(:status)
    statuses.create! name: status
  end
end
