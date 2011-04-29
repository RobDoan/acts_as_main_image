module Vaaia
  module HasImage

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def acts_as_image(attached_column_name,options={})
        default_option= {:min_size=>[270,110],
                         :url =>  "/system/images/:class/:style/:id/:filename",
                         :default_url => "/images/missing_images/:tag/missing_:style.png"}
        options = default_option.deep_merge!(options)

        has_attached_file attached_column_name, options

        cattr_accessor :main_image_size
        size_array = options[:min_size]
        self.main_image_size = { :width => size_array[0],
                                :height => size_array[1] }

        validates_attachment_content_type attached_column_name, :content_type => IMAGE_CONTENT_TYPES, :allow_nil => true
        if options[:max_size]
          validates_attachment_size       attached_column_name, :less_than    => options[:max_size].megabyte,
                                                                :if => :is_images?
        end

        before_validation :image_dimensions

        define_method "image_dimensions" do
          return true if self.try(attached_column_name).content_type == 'application/x-shockwave-flash'
          return true if self.try(attached_column_name).queued_for_write[:original].blank?
          begin
            dimensions = Paperclip::Geometry.from_file(self.try(attached_column_name).queued_for_write[:original])
            dimension_restrictions = self.class.main_image_size
            self.send("#{attached_column_name}_height=", dimensions.height) if self.respond_to?("#{attached_column_name}_height=")
            self.send("#{attached_column_name}_width=", dimensions.width)   if self.respond_to?("#{attached_column_name}_width=")
          end
        end

        define_method 'is_image?' do
          ['image/jpeg', 'image/gif', 'image/png', 'image/pjpeg', 'image/x-png'].include?(self.try(attached_column_name).content_type)
        end

        private :image_dimensions

        include InstanceMethods
      end

    end

    module InstanceMethods

    end

  end
end
