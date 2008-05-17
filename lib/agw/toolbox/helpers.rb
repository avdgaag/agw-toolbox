module AGW #:nodoc:
  module Toolbox #:nodoc:
    module Helpers
      # Shortcut method to <tt>#number_to_currency</tt> to make it
      # quickly output money amounts in euro's.
      #
      # Example usage:
      #
      #   in_euros(@product.price) # => &euro;123.456,90
      # 
      def in_euros(number)
        return number_to_currency(number, :precision => 2, :unit => '&euro;', :separator => ',', :delimiter => '.')
      end
      
      # Only execute the given block if the current user is logged in
      def logged_in_only
        yield if logged_in?
      end
      
      # Only execute the given block if the curret user is not logged in
      def public_only
        yield unless logged_in?
      end
    end
  end
end