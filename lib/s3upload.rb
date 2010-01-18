require 'openssl'
require 'digest/sha1'
require "base64"

module S3 
  class Upload
    
    attr_accessor :bucket, :expires, :secret_key, :access_key_id, :acl
    
    def initialize( access_key_id , secret_key , bucket , acl="public-read" , expires=nil)
      @access_key_id = access_key_id
      @secret_key = secret_key
      @bucket = bucket
      @acl = acl
      
      # default to one hour from now
      @expires = expires || (Time.now + 3600)
      
    end
    
    def to_xml( key , content_type )
      @key = key
      @content_type = content_type
      
      props = {
        :accessKeyId => access_key_id,
        :acl => acl,
        :bucket => bucket,
        :contentType => @content_type,
        :expires => expiration_str,
        :key => @key,
        :secure => false,
        :signature => signature,
        :policy => policy
      }

      # Create xml of the properties
      xml = "<s3>"
      props.each {|k,v| xml << "<#{k}>#{v}</#{k}>"}
      xml << "</s3>"
    end
    
    private
    
    def expiration_str
      @expires.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    end
    
    def policy
      @policy ||= Base64.encode64( "{
          'expiration': '#{expiration_str}',
          'conditions': [
              {'bucket': '#{bucket}'},
              {'key': '#{@key}'},
              {'acl': '#{acl}'},
              {'Content-Type': '#{@content_type}'},
              ['starts-with', '$Filename', ''],
              ['eq', '$success_action_status', '201']
          ]
      }").gsub(/\n|\r/, '')
    end
    
    def signature
      [OpenSSL::HMAC.digest(OpenSSL::Digest::Digest.new('sha1'), secret_key, policy)].pack("m").strip
    end
    
  end
end