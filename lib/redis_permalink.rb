require "redis_permalink/version"
require "active_support"
require "active_record"

module RedisPermalink
	extend ActiveSupport::Concern

	module ClassMethods
	  def redis_permalink_name
	    @redis_permalink_name
	  end

	  def redis_permalink_name=(v)
	    @redis_permalink_name = v
	  end

	  def redis_permalink_cache
	    @redis_permalink_cache
	  end

	  def redis_permalink_cache=(v)
	    @redis_permalink_cache = v
	  end	  

	  def permalink(name, cache=nil)
	  	self.redis_permalink_name = name
	  	self.redis_permalink_cache = cache

	    class_eval do
	    	def generate_permalink
		      list = self.redis_permalink_name.split(/ /)
		      
		      refined = []
		      list.size.times.each do |i|
		        w = list[i].gsub(/\W/, '')
		        refined << w if w != ""
		      end
		      return refined.join('-').downcase
		    end
		    
		    def permalink=(perma)
		      ap "Permalink is only updated on creation"
		    end
		    
		    def permalink
		      return self["permalink"] ? self["permalink"].downcase : ""
		    end
		    
		    def get_link(prefix="")
		      (prefix != "" ? "/#{prefix}/#{permalink}" : "/" + permalink.to_s).downcase
		    end

		    def self.via_permalink(perma)
		      if self.redis_permalink_cache
		        key = "#{self.name.underscore}:#{perma}"
		        id = self.redis_permalink_cache.get(key)
		        return self.find(id) if id
		      end
		      
		      # If not cached
		      obj = self.find_by_permalink(perma)
		      self.redis_permalink_cache.set(key, obj.id) if self.redis_permalink_cache
		      return obj
		    end

		    before_create { self['permalink'] = self.generate_permalink }
		    after_destroy { self.redis_permalink_cache.del(self['permalink']) if self.redis_permalink_cache }
	    end
	  end
	end
end

ActiveRecord::Base.send :include, RedisPermalink