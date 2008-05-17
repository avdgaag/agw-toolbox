module AGW #:nodoc:
  module Toolbox #:nodoc:
    module Validations
      def self.included(base)
        base.extend ClassMethods
      end
      
      module ClassMethods
        # Shortcut method to validates_format_of for validating
        # a given attribute is a valid e-mail address
        def validates_email_format_of(*attr_names)
          options = attr_names.last.is_a?(Hash) ? attr_names.pop : {}
          options.reverse_merge! :with => Regexp.email
          validates_format_of(attr_names, options)
        end

        # Shortcut method to validates_format_of for validating
        # a given attribute is a valid username: it must only contain
        # word characters and underscores and must be between 3 and 16
        # characters long.
        def validates_username_format_of(*attr_names)
          options = attr_names.last.is_a?(Hash) ? attr_names.pop : {}
          options.reverse_merge! :with => /\A[\w_]{3,16}\Z/i
          validates_format_of(attr_names, options)
        end

        # Shortcut method to validates_format_of for validating
        # a given attribute is a valid URL.
        def validates_url_format_of(*attr_names)
          options = attr_names.last.is_a?(Hash) ? attr_names.pop : nil
          options.reverse_merge! :with => Regexp.url
          validates_format_of(attr_names, options)
        end        
      end
    end
  end
end