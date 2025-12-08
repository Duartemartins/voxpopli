class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Generate UUID for all models using UUID primary keys
  before_create :set_uuid, if: -> { has_attribute?(:id) && id.nil? }

  private

  def set_uuid
    self.id = SecureRandom.uuid
  end
end
