module AGW #:nodoc:
  module Toolbox #:nodoc:
    module CoreExtensions #:nodoc:
      module StringExtensions
      
        # From Typo:
        # Converts a post title to its-title-using-dashes
        # All special chars are stripped in the process
        def to_url
          result = self.downcase
          result.gsub!(/['"]/, '')  # replace quotes by nothing
          result.gsub!(/&/, 'and')  # replace & by and
          result.gsub!(/€/, 'EUR')  # replace € by EUR
          result.gsub!(/\W/, ' ')   # strip all non word chars
          result.gsub!(/“|”|‘|’|–|—/, ' ')   # strip all typographic characters
          result.gsub!(/\ +/, '-')  # replace all white space sections with a dash
          result.gsub!(/(-)$/, '')  # trim dashes
          result.gsub!(/^(-)/, '')
          result
        end
      end
      
      module ArrayExtensions
        
        # Generate an HTML list directly from this array.
        # Array items are wrapped in <tt>li</tt>-tags and the array of
        # items is wrapped in a <tt>ol</tt>-tag by default.
        #
        # You can change the type of list (<tt>ul</tt> or <tt>ol</tt>) and any
        # HTML attributes of the list as follows:
        #
        #   @posts.to_list :type => :ul, :id => 'list_of_posts'
        # 
        def to_html_list(options = {})
          # set default list type to OL
          options = { :type => :ol }.merge(options)
          type = options.delete(:type)
          raise ArgumentError if type.nil?
          
          # HTML attributes for the list element
          attributes = options.to_attributes
          
          self.inject("<#{type}#{attributes}>\n") { |output, item| output << "\t<li>#{item}</li>\n" } << "</#{type}>\n" if self.any?
        end
        
        # Override the default behaviour of <tt>#to_sentence</tt>. Only
        # the default options have changed, so it can still be used in
        # the same way.
        def to_sentence(options = {})
          options.reverse_merge! :skip_last_comma => true
          super(options)
        end
        
        # Return self without the specified items
        def except(*items)
          self.reject { |item| items.include?(item) }
        end
      end
      
      module HashExtensions
        
        # Generate an HTML definition list directly from this Hash.
        # Keys are wrapped in DT-tags and values in DD-tags. The result
        # is wrapped in a DL-tag.
        # 
        # Extra HTML attributes for the DL-tag can be passed in as follows:
        #
        #   attributes.to_html_list :id => 'post_attributes', :class => 'highlight'
        # 
        def to_html_list(options = {})
          attributes = options.to_attributes
          self.inject("<dl#{attributes}>\n") { |o, p| o << "\t<dt>#{p[0]}</dt>\n\t<dd>#{p[1]}</dd>\n" } << "</dl>\n" if self.any?
        end
      
        # Returns a copy of self without the specified keys. Usage:
        # 
        #   { :a => 1, :b => 2, :c => 3}.except(:a) -> { :b => 2, :c => 3}
        # 
        def except(*keys)
          self.reject { |k,v| keys.include? k.to_sym }
        end
      
        # Return a copy of self with only the specified keys. Usage:
        # 
        #   { :a => 1, :b => 2, :c => 3}.only(:a) -> {:a => 1}
        # 
        def only(*keys)
          self.dup.reject { |k,v| !keys.include? k.to_sym }
        end
        
        # use to output a hash like { 0 => 'some value', 1 => 'some other value' } to
        # an array for use in rails' select elements, such as
        # [ ['some value', 0], ['some other value', 1] ]. Now the hash is nicely sorted.
        def to_select_options
          self.keys.sort.inject([]) { |output, key| output << [self[key], key] }
        end
        
        # build HTML attributes out keys and values. A space is
        # appended at the resulting string.
        #
        # Usage:
        # 
        #   { :id => 'a', :class => 'b' }.to_attributes # => ' id="a" class="b"'
        # 
        def to_attributes
          self.inject('') { |list, pair| list << (' %s="%s"' % pair) }
        end
      end
      
      module TimeExtensions
      
        # Returns whether this time is in the future or not
        #
        # Example:
        #
        #   3.days.since.future? # => true
        # 
        def future?
          (self <=> Time.now) == 1
        end
      
        # Returns whether this time is in the past or not.
        #
        # Example:
        #
        #   3.days.ago.past? # => true
        # 
        def past?
          (self <=> Time.now) < 1
        end
      
        # Return the number of days that self lies in the past.
        def days_ago
          (self <=> Time.now) < 1 ? (Time.now - self) / 86400 : 0
        end
      
      end
      
      module IntegerExtensions
        
        # Returns whether <tt>self</tt> is in the given Range.
        # This is equivalent to calling <tt>range.include(self)</tt>.
        #
        # Example usage:
        #
        #   return if age.in?(18..25)
        # 
        def in?(range)
          return range.include?(self)
        end
      end
      
      module RegexExtensions
      
        #
        # RFC822 Email Address Regex
        # --------------------------
        # 
        # Originally written by Cal Henderson
        # c.f. http://iamcal.com/publish/articles/php/parsing_email/
        #
        # Translated to Ruby by Tim Fletcher, with changes suggested by Dan Kubb.
        #
        # Licensed under a Creative Commons Attribution-ShareAlike 2.5 License
        # http://creativecommons.org/licenses/by-sa/2.5/
        #       
        def email
          qtext          = '[^\\x0d\\x22\\x5c\\x80-\\xff]'
          dtext          = '[^\\x0d\\x5b-\\x5d\\x80-\\xff]'
          atom           = '[^\\x00-\\x20\\x22\\x28\\x29\\x2c\\x2e\\x3a-' + '\\x3c\\x3e\\x40\\x5b-\\x5d\\x7f-\\xff]+'
          quoted_pair    = '\\x5c[\\x00-\\x7f]'
          domain_literal = "\\x5b(?:#{dtext}|#{quoted_pair})*\\x5d"
          quoted_string  = "\\x22(?:#{qtext}|#{quoted_pair})*\\x22"
          domain_ref     = atom
          sub_domain     = "(?:#{domain_ref}|#{domain_literal})"
          word           = "(?:#{atom}|#{quoted_string})"
          domain         = "#{sub_domain}(?:\\x2e#{sub_domain})*"
          local_part     = "#{word}(?:\\x2e#{word})*"
          addr_spec      = "#{local_part}\\x40#{domain}"
          pattern        = /\A#{addr_spec}\z/
        end
        
        # Immediatly return a standard regular expression for matching valid URLs.
        def url
          /^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/ix
        end
      end

      String.send   :include, AGW::Toolbox::CoreExtensions::StringExtensions
      Array.send    :include, AGW::Toolbox::CoreExtensions::ArrayExtensions
      Hash.send     :include, AGW::Toolbox::CoreExtensions::HashExtensions
      Integer.send  :include, AGW::Toolbox::CoreExtensions::IntegerExtensions
      Time.send     :include, AGW::Toolbox::CoreExtensions::TimeExtensions
      Regexp.send   :extend,  AGW::Toolbox::CoreExtensions::RegexExtensions
    end
  end
end