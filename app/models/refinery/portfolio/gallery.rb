module Refinery
  module Portfolio
    class Gallery < Refinery::Core::BaseModel
      acts_as_indexed :fields => [:title, :body]
      acts_as_nested_set :dependent => :destroy

      extend FriendlyId
      friendly_id :title, :use => [:slugged]
      translates :title, :body

      class Translation
        attr_accessible :locale
      end

      has_many    :items, :dependent => :destroy

      attr_accessible   :title, :body, :lft, :rgt,
                        :position, :gallery_type, :depth,
                        :parent_id, :items_attributes

      alias_attribute :description, :body

      validates :title, :presence => true

      after_save :bulk_update_associated_items

      def cover_image
        items.sort_by(&:position).first if items.present?
      end

      def items_attributes=(items_attributes = {})
        #@image_ids = ids.reject(&:empty?).map(&:to_i).uniq
        @items_attributes = items_attributes.delete_if {|k, v| k.empty? }
      end

      # Don't upload duplicate images
      def bulk_update_associated_items
        return unless @items_attributes.present?

        @items_attributes.each_with_index do |(k, item), position|
          update_position_or_create_item(item[:image_id].to_i, position, item[:caption]) unless item[:image_id].empty?
        end

        delete_removed_items
      end

      private

      def existing_image_ids
        @existing_image_ids ||= self.items.pluck(:image_id)
      end

      def update_position_or_create_item(image_id, position, caption = "")
        # If that image ID already exists, update its item's position
        if existing_image_ids.include? image_id
          items.find_by_image_id(image_id).update_attributes({:position => position, :caption => caption})
        # If image_id is not in existing_ids, create a new one

        else
          ::Refinery::Portfolio::Item.create({
            :title => "#{title} #{position}",
            :position => position,
            :gallery_id => id,
            :image_id => image_id,
            :caption => caption
          })
        end
      end

      def delete_removed_items
        # Array#- will find all entries existing in the first array that do not exist in
        # the second. In this case, we want to find which item id existed before but
        # does not exist in the new array of item ids, because it's these items we
        # want to delete.
        #
        # That is:
        # [1 2 3] - [1 2 4] = [3]
        removed_items = items.find_all_by_image_id(existing_image_ids - @items_attributes.values.map {|i| i[:image_id].to_i})
        removed_items.map(&:destroy)
      end
    end
  end
end
