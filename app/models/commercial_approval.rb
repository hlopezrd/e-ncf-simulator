class CommercialApproval < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  validates :rnc_emisor, presence: true
  validates :rnc_comprador, presence: true
  validates :encf, presence: true
  validates :estado, presence: true
  validates :xml_content, presence: true
end
