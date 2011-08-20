module Puret
  module ActiveRecordExtensions
    module ClassMethods
      # Configure translation model dependency.
      # Eg:
      #   class PostTranslation < ActiveRecord::Base
      #     puret_for :post
      #   end
      def puret_for(model)
        belongs_to model
        validates_presence_of model, :locale
        validates_uniqueness_of :locale, :scope => "#{model}_id"
      end
      

      # Configure translated attributes.
      # Eg:
      #   class Post < ActiveRecord::Base
      #     puret :title, :description
      #   end
      def puret(*attributes)
        make_it_puret! unless included_modules.include?(InstanceMethods)

        attributes.each do |attribute|

          #dynamic finders 
          (class << self; self; end).class_eval do
            define_method "find_by_#{attribute}" do |value|
              self.send("find_all_by_#{attribute}".to_sym, value).first
            end
            define_method "find_all_by_#{attribute}" do |value|
              joins(:translations).where("#{self.to_s.tableize.singularize}_translations.locale" => I18n.locale, "#{self.to_s.tableize.singularize}_translations.#{attribute}" => "#{value}")
            end
          end

          
          # this make possible to specify getter and setter methods per locale, 
          # eg: given title attribute you can use getter
          # as: title_en or title_it and setter as title_en= and title_it=
          I18n.available_locales.each do |locale|

            define_method "#{attribute}_#{locale}=" do |value|
              set_attribute(attribute,value, locale)
            end

            define_method "#{attribute}_#{locale}" do 
              return puret_attributes[locale][attribute] if puret_attributes[locale][attribute]
              return if new_record?
              translations.where(:locale => locale).first.send(attribute.to_sym) rescue nil 
            end
          end

          # attribute setter
          define_method "#{attribute}=" do |value|
            set_attribute(attribute, value)
          end

          # attribute getter
          define_method attribute do
            # return previously setted attributes if present
            return puret_attributes[I18n.locale][attribute] if puret_attributes[I18n.locale][attribute]
            return if new_record?

            # Lookup chain:
            # if translation not present in current locale,
            # use default locale, if present.
            # Otherwise use first translation
            translation = translations.detect { |t| t.locale.to_sym == I18n.locale && t[attribute] } ||
              translations.detect { |t| t.locale.to_sym == puret_default_locale && t[attribute] } ||
              translations.first

            translation ? translation[attribute] : nil
          end

          define_method "#{attribute}_before_type_cast" do
            self.send(attribute)
          end
        end
      end

      private

      # configure model
      def make_it_puret!
        include InstanceMethods

        has_many :translations, :class_name => "#{self.to_s}Translation", :dependent => :destroy, :order => "created_at DESC"
        after_save :update_translations!
      end
    end

    module InstanceMethods
            
      def set_attribute(attribute, value, locale = I18n.locale)
        puret_attributes[locale][attribute] = value
      end

      def find_or_create_translation(locale)
        locale = locale.to_s
        (find_translation(locale) || self.translations.new).tap do |t|
          t.locale = locale
        end
      end


      def all_translations
        t = I18n.available_locales.map do |locale|
          [locale, find_or_create_translation(locale)]
        end
        ActiveSupport::OrderedHash[t]
      end


      def find_translation(locale)
        locale = locale.to_s
        translations.detect { |t| t.locale == locale }
      end


      def puret_default_locale
        return default_locale.to_sym if respond_to?(:default_locale)
        return self.class.default_locale.to_sym if self.class.respond_to?(:default_locale)
        I18n.default_locale
      end

      # attributes are stored in @puret_attributes instance variable via setter
      def puret_attributes
        @puret_attributes ||= Hash.new { |hash, key| hash[key] = {} }
      end

      # called after save
      def update_translations!
        return if puret_attributes.blank?
        puret_attributes.each do |locale, attributes|
          translation = translations.find_or_initialize_by_locale(locale.to_s)
          translation.attributes = translation.attributes.merge(attributes)
          translation.save!
        end
      end
    end
  end
end

ActiveRecord::Base.extend Puret::ActiveRecordExtensions::ClassMethods
