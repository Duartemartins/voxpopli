class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Generate UUID for all models using UUID primary keys
  before_create :set_uuid

  private

  def set_uuid
    column = self.class.columns_hash['id']
    return unless column
    
    # Check if it's a UUID column (SQLite stores UUIDs as strings with sql_type 'uuid')
    if column.sql_type == 'uuid' || column.type == :uuid
      self.id ||= SecureRandom.uuid
    end
  end
end
