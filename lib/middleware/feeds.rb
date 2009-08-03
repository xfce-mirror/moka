require 'rubygems'

gem 'ratom', '0.6.2'
require 'atom'

module Moka
  module Middleware
    class Feeds

      attr_accessor :base_url

      def initialize(app)
        @app = app
        @base_url = ''
        yield self if block_given?
      end

      def project_feed_url(&block)
        @project_feed_url_fn = block if block_given?
      end

      def get_project_feed_url(project)
        @project_feed_url_fn.call(project)
      end

      def project_feed_filename(&block)
        @project_feed_filename_fn = block if block_given?
      end

      def project_body(&block)
        @project_body_fn = block if block_given?
      end

      def collection_feed_url(&block)
        @collection_feed_url_fn = block if block_given?
      end

      def get_collection_feed_url(collection)
        @collection_feed_url_fn.call(collection)
      end

      def collection_feed_filename(&block)
        @collection_feed_filename_fn = block if block_given?
      end

      def collection_body(&block)
        @collection_body_fn = block if block_given?
      end

      def supports_release?(release)
        if release.is_a? Moka::Models::Collection::Release
          !@collection_feed_url_fn.nil? \
            and !@collection_feed_filename_fn.nil? \
            and !@collection_body_fn.nil?
        else
          !@project_feed_url_fn.nil? \
            and !@project_feed_filename_fn.nil? \
            and !@project_body_fn.nil?
        end
      end

      def announce_release(release, message, sender)
        return unless supports_release?(release)
        if release.is_a? Moka::Models::Collection::Release
          announce_collection_release(release, message, sender)
        else
          announce_project_release(release, message, sender)
        end
      end

      def announce_collection_release(release, message, sender)
        filename = @collection_feed_filename_fn.call(release.collection)

        feed = nil

        if File.exists?(filename)
          open(filename) do |file|
            begin
              file.flock(File::LOCK_SH)
              feed = Atom::Feed.load_feed(file)
            ensure
              file.flock(File::LOCK_UN)
            end
          end
        else
          dirname = File.dirname(filename)
          File.makedirs(dirname) unless File.directory?(dirname)

          feed = Atom::Feed.new do |feed|
            feed.title = "#{release.collection.display_name} Release Feed"
            feed.links << Atom::Link.new(:href => release.collection.website)
            feed.subtitle = "Release announcements for #{release.collection.display_name}"
          end
        end

        feed.updated = Time.now

        entry = Atom::Entry.new do |entry|
          entry.title = "#{release.collection.display_name} #{release.version} released"
          entry.authors << Atom::Person.new(:name => sender.realname, :email => sender.email)
          entry.published = Time.now
          entry.updated = Time.now
          entry.id = "#{release.collection.name}-#{release.version}"
          entry.content = Atom::Content::Html.new(@collection_body_fn.call(release, message, sender))
        end

        feed.entries.unshift(entry)

        File.open(filename, 'w+') do |file|
          begin
            file.flock(File::LOCK_EX)
            file.write(feed.to_xml)
          ensure
            file.flock(File::LOCK_UN)
          end
        end
      end

      def announce_project_release(release, message, sender)
        filename = @project_feed_filename_fn.call(release.project)

        feed = nil

        if File.exists?(filename)
          open(filename) do |file|
            begin
              file.flock(File::LOCK_SH)
              feed = Atom::Feed.load_feed(file)
            ensure
              file.flock(File::LOCK_UN)
            end
          end
        else
          dirname = File.dirname(filename)
          File.makedirs(dirname) unless File.directory?(dirname)

          feed = Atom::Feed.new do |feed|
            feed.title = "#{release.project.name} Release Feed"
            feed.links << Atom::Link.new(:href => release.project.website)
            feed.subtitle = "Release announcements for #{release.project.name}"
          end
        end

        feed.updated = Time.now

        entry = Atom::Entry.new do |entry|
          entry.title = "#{release.project.name} #{release.version} released"
          entry.authors << Atom::Person.new(:name => sender.realname, :email => sender.email)
          entry.published = Time.now
          entry.updated = Time.now
          entry.id = "#{release.project.name}-#{release.version}"
          entry.content = Atom::Content::Html.new(@project_body_fn.call(release, message, sender))
        end

        feed.entries.unshift(entry)

        open(filename, 'w+') do |file|
          begin
            file.flock(File::LOCK_EX)
            file.write(feed.to_xml)
          ensure
            file.flock(File::LOCK_UN)
          end
        end
        File.chmod(0664, filename)
      end

      def delete_collection_release(release)
        filename = @project_feed_filename_fn.call(release.project)

        if File.exists?(filename)
          feed = nil

          open(filename) do |file|
            begin
              file.flock(File::LOCK_SH)
              feed = Atom::Feed.load_feed(file)
            ensure
              file.flock(File::LOCK_UN)
            end
          end

          if feed
            for entry in feed.entries 
              if entry.id == "#{release.collection.name}-#{release.version}"
                feed.entries.delete(entry)
              end
            end

            open(filename, 'w+') do |file|
              begin
                file.flock(File::LOCK_EX)
                file.write(feed.to_xml)
              ensure
                file.flock(File::LOCK_UN)
              end
            end
          end
        end
      end

      def delete_project_release(release)
        filename = @project_feed_filename_fn.call(release.project)

        if File.exists?(filename)
          feed = nil

          open(filename) do |file|
            begin
              file.flock(File::LOCK_SH)
              feed = Atom::Feed.load_feed(file)
            ensure
              file.flock(File::LOCK_UN)
            end
          end

          if feed
            for entry in feed.entries 
              if entry.id == "#{release.project.name}-#{release.version}"
                feed.entries.delete(entry)
              end
            end

            open(filename, 'w+') do |file|
              begin
                file.flock(File::LOCK_EX)
                file.write(feed.to_xml)
              ensure
                file.flock(File::LOCK_UN)
              end
            end
          end
        end
      end

      def delete_release(release)
        return unless supports_release?(release)

        if release.is_a? Moka::Models::Collection::Release
          delete_collection_release(release)
        else
          delete_project_release(release)
        end
      end

      def call(env)
        request = Rack::Request.new(env)
        env['feeds'] = self
        status, headers, body = @app.call(env)
        response = Rack::Response.new(body, status, headers)
        response.to_a
      end

    end
  end
end
