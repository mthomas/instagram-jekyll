require 'yaml'
require 'jekyll'
require 'instagram'

#
# Usage:
#   
#	{% instagram accesstokenpath:C:\instagram-access-token.txt %}
#		<div>
#			<h3>{{ item.caption.text }}</h3>
#			<img src="{{ item.images.standard_resolution.url }}" />
#		</div>
#	{% endinstagram %}
#
# Parameters:
#   accesstokenpath: the path to a text file containing an oauth access token for Instagram

class InstagramLoader
	class << self
		def photos(accesstokenpath)
			accesstoken = File.open(accesstokenpath).gets
			client = Instagram.client(:access_token => accesstoken)
			client.user_recent_media
		end
	end
end


module Jekyll
  class InstagramTag < Liquid::Block

    include Liquid::StandardFilters
    Syntax = /(#{Liquid::QuotedFragment}+)?/ 

    def initialize(tag_name, markup, tokens)
      @variable_name = 'item'
      @attributes = {}
      
      # Parse parameters
      if markup =~ Syntax
        markup.scan(Liquid::TagAttributes) do |key, value|
          #p key + ":" + value
          @attributes[key] = value
        end
      else
        raise SyntaxError.new("Syntax Error in 'delicious' - Valid syntax: instagram accesstokenpath:x]")
      end

      @accesstoken = @attributes['accesstokenpath']
      @name = 'item'

      super
    end

    def render(context)
      context.registers[:instagram] ||= Hash.new(0)
    
	  collection = InstagramLoader.photos(@accesstoken)
      
      length = collection.length
      result = []
              
      # loop through found photos and render results
      context.stack do
        collection.each_with_index do |item, index|
          attrs = item
          context[@variable_name] = attrs
          context['forloop'] = {
            'name' => @name,
            'length' => length,
            'index' => index + 1,
            'index0' => index,
            'rindex' => length - index,
            'rindex0' => length - index -1,
            'first' => (index == 0),
            'last' => (index == length - 1) }

          result << render_all(@nodelist, context)
        end
      end
      result
    end
  end
end

Liquid::Template.register_tag('instagram', Jekyll::InstagramTag)
