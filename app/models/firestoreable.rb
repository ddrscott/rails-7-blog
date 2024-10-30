require 'google/cloud/firestore'

module Firestoreable
  extend ActiveSupport::Concern

  included do
    self.firestore_client = Google::Cloud::Firestore.new
    self.collection_name = table_name.to_s.singularize.pluralize
  end

  module ClassMethods
    attr_accessor :firestore_client, :collection_name

    def initialize_firestore
      @firestore_client ||= Google::Cloud::Firestore.new
      @collection_name ||= table_name.to_s.singularize.pluralize
    end

    def firestore_client=(client)
      @firestore_client = client
    end

    def collection_name=(name)
      @collection_name = name
    end

    def create(attributes = {})
      record = new(attributes)
      record.save!
      record
    end

    def find(id)
      doc_ref = @firestore_client.doc("#{@collection_name}/#{id}")
      if (doc = doc_ref.get).exists?
        new(doc.data.merge(id: doc.path.split('/')[-1]))
      else
        raise ActiveRecord::RecordNotFound.new("Couldn't find #{self.name} with 'id'=#{id}")
      end
    end

    def all
      initialize_firestore
      @firestore_client.get_all(@collection_name).map { |doc| new(doc.data.merge(id: doc.path.split('/')[-1])) }
    end

    def where(query)
      if query.is_a?(Hash) && query.length == 1
        key, value = query.first
        @firestore_client.collection(@collection_name).where(key.to_s, '==', value).documents.map { |doc| new(doc.data.merge(id: doc.path.split('/')[-1])) }
      else
        raise NotImplementedError.new("Firestoreable only supports simple equality queries for now")
      end
    end

    def update_all(attributes)
      @firestore_client.collection(@collection_name).update do |batch|
        all.each do |record|
          batch.update(record.firestore_record.ref, attributes)
        end
      end
    end

    def destroy_all
      @firestore_client.collection(@collection_name).delete
    end
  end

  attr_accessor :id, :attributes

  def initialize(attributes = {})
    @attributes = attributes.dup
    define_singleton_methods_for_attributes
  end

  private

  def delegate_missing_to(target)
    ->(method, *args, &block) { target.send(method, *args, &block) }
  end

  def create_record
    doc_ref = @firestore_client.collection(@collection_name).doc
    doc_ref.set(@attributes)
    self.id = doc_ref.path.split('/')[-1]
  end

  def update_record
    firestore_record.ref.update(@attributes)
  end

  def firestore_record
    @firestore_record ||= @firestore_client.doc("#{@collection_name}/#{id}")
  end

  def define_singleton_methods_for_attributes
    @attributes.each do |key, value|
      define_singleton_method(key) { @attributes[key] }
      define_singleton_method("#{key}=") { |val| @attributes[key] = val }
    end
  end
end
