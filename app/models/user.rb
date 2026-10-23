class User < ApplicationRecord
  acts_as_paranoid
  has_paper_trail
  belongs_to :role

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
