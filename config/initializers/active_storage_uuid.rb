# frozen_string_literal: true

# Active Storage models don't inherit from ApplicationRecord, so they
# don't get the UUID generation callback. Add it here.
Rails.application.config.to_prepare do
  ActiveStorage::Blob.class_eval do
    before_create :set_uuid, if: -> { has_attribute?(:id) && id.nil? }

    private

    def set_uuid
      self.id = SecureRandom.uuid
    end
  end

  ActiveStorage::Attachment.class_eval do
    before_create :set_uuid, if: -> { has_attribute?(:id) && id.nil? }

    private

    def set_uuid
      self.id = SecureRandom.uuid
    end
  end

  ActiveStorage::VariantRecord.class_eval do
    before_create :set_uuid, if: -> { has_attribute?(:id) && id.nil? }

    private

    def set_uuid
      self.id = SecureRandom.uuid
    end
  end
end
