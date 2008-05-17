module AGW
  module Toolbox
    module PlaceholderHelper

      # Create a placeholder message that can be used when there
      # are no results to display in a listing or search results set.
      # A simple HTML div element is returned with the given
      # message as contents. The message defaults to 'Er is niets
      # om weer te geven.'
      #
      # Example usage:
      #
      #   placeholder() # => <div class="placeholder">Er is niets om weer te geven</p>
      #   placeholder('Niets') # => <div class="placeholder">Niets</p>
      #   placeholder('Niets', :span) # => <span class="placeholder">Niets</span>
      #
      def placeholder(label = 'Er is niets om weer te geven.', options = {})
        label ||= 'Er is niets om weer te geven.'
        options.reverse_merge! :tag => 'div', :class => 'placeholder'
        content_tag(options.delete(:tag), label, options)
      end
      alias_method :ph, :placeholder

      # This is a micro placeholder function, used to quickly output
      # either a value or a default message.
      #
      # Example usage:
      # 
      #   <%= phf(@post.title) %> # => <span class="placeholder">Niet opgegeven</span
      #
      def placeholder_for(string, label = 'Niet opgegeven', options = { :tag => :span} )
        string.blank? ? placeholder(label, options) : h(string)
      end
      alias_method :phf, :placeholder_for

      # When given a statement that evaluates to true or false, this method
      # will either print the given block to the page (on true) or return
      # a placeholder using the <tt>#placeholder</tt> method. After the condition
      # the same options can be passed to this method as to <tt>#placeholder</tt>.
      #
      # Example usage:
      #
      #   <% placeholder_unless(@posts.any?, 'there are no posts') do %>
      #     <%= render :partial => @posts %>
      #   <% end %>
      #
      # When <tt>@posts.any?</tt> evaluates to false, this will result in:
      #
      #   <p class="placeholder">there are no posts</p>
      #
      # Otherwise, it will evaluate the code block and render the partial.
      def placeholder_unless(condition, *args, &block)
        return condition ? concat(capture(&block), block.binding) : concat(placeholder(*args), block.binding)
      end
      alias_method :phu, :placeholder_unless
  
      # TODO: document this method
      # TODO: test this method
      def placeholder_with_blank_slate_unless(condition, name, &block)
        return condition ? concat(capture(&block), block.binding) : concat(image_tag("blank-slate-#{name}.png", :alt => "Voorbeeld van #{name}"), block.binding)
      end
      alias_method :pbs, :placeholder_with_blank_slate_unless
    end
  end
end    