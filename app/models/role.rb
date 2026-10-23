class Role < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
end
