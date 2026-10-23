class User < ApplicationRecord
  belongs_to :role

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
