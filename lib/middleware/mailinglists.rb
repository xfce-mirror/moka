require 'rubygems'

gem 'pony', '0.3'
require 'pony'

module Moka
  module Middleware
    class Mailinglists
      attr_accessor :lists

      def initialize(app)
        @app = app
        yield self if block_given?
      end

      def project_subject(&block)
        @project_subject_fn = block if block_given?
      end

      def project_body(&block)
        @project_body_fn = block if block_given?
      end

      def collection_subject(&block)
        @collection_subject_fn = block if block_given?
      end

      def collection_body(&block)
        @collection_body_fn = block if block_given?
      end

      def supports_release?(release)
        if release.is_a? Moka::Models::Collection::Release
          !@collection_subject_fn.nil? and !@collection_body_fn.nil?
        else
          !@project_subject_fn.nil? and !@project_body_fn.nil?
        end
      end

      def announce_release(release, message, sender, recipients)
        return unless supports_release?(release)

        if release.is_a? Moka::Models::Collection::Release
          subject = @collection_subject_fn.call(release, message, sender)
          body = @collection_body_fn.call(release, message, sender)
        else 
          subject = @project_subject_fn.call(release, message, sender)
          body = @project_body_fn.call(release, message, sender)
        end

        recipients = [ recipients ] unless recipients.is_a? Array
          
        for recipient in recipients 
          Pony.mail(:from => sender.display_email,
                    :to => recipient, 
                    :subject => subject, 
                    :body => body)
        end
      end

      def call(env)
        request = Rack::Request.new(env)
        env['mailinglists'] = self
        status, headers, body = @app.call(env)
        response = Rack::Response.new(body, status, headers)
        response.to_a
      end
    end
  end
end
