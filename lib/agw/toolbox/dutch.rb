module AGW #:nodoc:
  module Toolbox #:nodoc:
    module Dutch
      def self.setup
        # Install new time formats
        Time::DATE_FORMATS[:short]     = "%d-%m-%y %H:%M"
        Time::DATE_FORMATS[:tiny_date] = "%d %b"
        Time::DATE_FORMATS[:code]      = '%d%m%y%H%M'

        ::ActiveRecord::Base.send :include, ActiveRecord
      end
      
      module ActiveRecord #:nodoc:
        class Errors
          begin
          @@default_error_messages = {
            :inclusion                =>  "komt niet voor op de lijst",
            :exclusion                =>  "is voorbehouden",
            :invalid                  =>  "is ongeldig",
            :confirmation             =>  "komt niet overeen met de bevestiging",
            :accepted                 =>  "moet geaccepteerd worden",
            :empty                    =>  "kan niet leeg zijn",
            :blank                    =>  "kan niet ontbreken",
            :too_long                 =>  "is te lang (maximum is %d tekens)",
            :too_short                =>  "is te kort (minimum is %d tekens)",
            :wrong_length             =>  "heeft de verkeerde lengte (moet %d tekens zijn)",
            :taken                    =>  "is al bezet",
            :not_a_number             =>  "is geen getal",
            :greater_than             =>  "moet groter zijn dan %d",
            :greater_than_or_equal_to =>  "moet groter of gelijk zijn aan %d",
            :equal_to                 =>  "moet gelijk zijn aan %d",
            :less_than                =>  "moet minder zijn dan %d",
            :less_than_or_equal_to    =>  "moet minder of gelijk zijn aan %d",
            :odd                      =>  "moet oneven zijn",
            :even                     =>  "moet even zijn"
          }
          end
        end
      end
    end
  end
end