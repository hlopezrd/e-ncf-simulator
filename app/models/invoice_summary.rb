class InvoiceSummary < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  validates :rnc_emisor, presence: true
  validates :encf, presence: true
  validates :xml_content, presence: true
end
