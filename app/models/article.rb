class Article < ApplicationRecord
  include ActAsFireRecordBeta
  include Visible

  firestore_attribute :title, :string
  firestore_attribute :body, :string
  firestore_attribute :created_at, :datetime
  firestore_attribute :updated_at, :datetime
  firestore_attribute :status, :string

  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 10 }
end
