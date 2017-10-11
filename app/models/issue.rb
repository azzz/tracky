class Issue < ApplicationRecord
  STATUSES = %w[pending in_progress resolved].freeze

  belongs_to :author, class_name: 'User', inverse_of: :issues
  belongs_to :assignee, class_name: 'User', inverse_of: :assigned_issues, optional: true

  has_many :statuses, dependent: :destroy

  validates :title, :status, :author, presence: true
  validates :status, inclusion: {in: STATUSES}
  validates :assignee, presence: true, if: ->(issue) { issue.status.in?(STATUSES) && !issue.pending? }

  after_save :save_status

  STATUSES.each do |status_name|
    define_method "#{status_name}?" do
      status == status_name
    end
  end

  private

  def save_status
    return unless saved_changes.include?(:status)
    statuses.create! name: status
  end
end
