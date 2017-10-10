class User < ApplicationRecord
  has_secure_password

  ROLES = %w[client manager].freeze

  has_many :issues, foreign_key: 'author_id', inverse_of: :author, dependent: :destroy
  has_many :assigned_issues, foreign_key: 'assignee_id', inverse_of: :assignee,
                             dependent: :nullify, class_name: 'Issue'

  validates :email, :full_name, :role, presence: true
  validates :role, inclusion: {in: ROLES}
  validates :email, uniqueness: true
end
