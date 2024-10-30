class Comment < ApplicationRecord
  include ActAsFireRecordBeta
  include Visible

  firestore_attribute :commenter, :string
  firestore_attribute :body, :string
  firestore_attribute :article_id, :string
  firestore_attribute :created_at, :datetime
  firestore_attribute :updated_at, :datetime
  firestore_attribute :status, :string

  belongs_to :article
end
