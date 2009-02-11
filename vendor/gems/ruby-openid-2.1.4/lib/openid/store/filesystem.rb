require 'fileutils'
require 'pathname'
require 'tempfile'

require 'openid/util'
require 'openid/store/interface'
require 'openid/association'

module OpenID
  module Store
    class Filesystem < Interface
      @@FILENAME_ALLOWED = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-".split("")

      # Create a Filesystem store instance, putting all data in +directory+.
      def initialize(directory)
        p_dir = Pathname.new(directory)
        @nonce_dir = p_dir.join('nonces')
        @association_dir = p_dir.join('associations')
        @temp_dir = p_dir.join('temp')

        self.ensure_dir(@nonce_dir)
        self.ensure_dir(@association_dir)
        self.ensure_dir(@temp_dir)
      end

      # Create a unique filename for a given server url and handle. The
      # filename that is returned will contain the domain name from the
      # server URL for ease of human inspection of the data dir.
      def get_association_filename(server_url, handle)
        unless server_url.index('://')
          raise ArgumentError, "Bad server URL: #{server_url}"
        end

        proto, rest = server_url.split('://', 2)
        domain = filename_escape(rest.split('/',2)[0])
        url_hash = safe64(server_url)
        if handle
          handle_hash = safe64(handle)
        else
          handle_hash = ''
        end
        filename = [proto,domain,url_hash,handle_hash].join('-')
        @association_dir.join(filename)
      end

      # Store an association in the assoc directory
      def store_association(server_url, association)
        assoc_s = association.serialize
        filename = get_association_filename(server_url, association.handle)
        f, tmp = mktemp

        begin
          begin
            f.write(assoc_s)
            f.fsync
          ensure
            f.close
          end

          begin
            File.rename(tmp, filename)
          rescue Errno::EEXIST

            begin
              File.unlink(filename)
            rescue Errno::ENOENT
              # do nothing
            end

            File.rename(tmp, filename)
          end

        rescue
          self.remove_if_present(tmp)
          raise
        end
      end

      # Retrieve an association
      def get_association(server_url, handle=nil)
        # the filename with empty handle is the prefix for the associations
        # for a given server url
        filename = get_association_filename(server_url, handle)
        if handle
          return _get_association(filename)
        end
        assoc_filenames = Dir.glob(filename.to_s + '*')

        assocs = assoc_filenames.collect do |f|
          _get_association(f)
        end

        assocs = assocs.find_all { |a| not a.nil? }
        assocs = assocs.sort_by { |a| a.issued }

        return nil if assocs.empty?
        return assocs[-1]
      end

      def _get_association(filename)
        begin
          assoc_file = File.open(filename, "r")
        rescue Errno::ENOENT
          return nil
        else
          begin
            assoc_s = assoc_file.read
          ensure
            assoc_file.close
          end

          begin
            association = Association.deserialize(assoc_s)
          rescue
            self.remove_if_present(filename)
            return nil
          end

          # clean up expired associations
          if association.expires_in == 0
            self.remove_if_present(filename)
            return nil
          else
            return association
          end
        end
      end

      # Remove an association if it exists, otherwise do nothing.
      def remove_association(server_url, handle)
        assoc = get_association(server_url, handle)

        if assoc.nil?
          return false
        else
          filename = get_association_filename(server_url, handle)
          return self.remove_if_present(filename)
        end
      end

      # Return whether the nonce is valid
      def use_nonce(server_url, timestamp, salt)
        return false if (timestamp - Time.now.to_i).abs > Nonce.skew

        if server_url and !server_url.empty?
          proto, rest = server_url.split('://',2)
        else
          proto, rest = '',''
        end
        raise "Bad server URL" unless proto && rest

        domain = filename_escape(rest.split('/',2)[0])
        url_hash = safe64(server_url)
        salt_hash = safe64(salt)

        nonce_fn = '%08x-%s-%s-%s-%s'%[timestamp, proto, domain, url_hash, salt_hash]

        filename = @nonce_dir.join(nonce_fn)

        begin
          fd = File.new(filename, File::CREAT | File::EXCL | File::WRONLY, 0200)
          fd.close
          return true
        rescue Errno::EEXIST
          return false
        end
      end

      # Remove expired entries from the database. This is potentially expensive,
      # so only run when it is acceptable to take time.
      def cleanup
        cleanup_associations
        cleanup_nonces
      end

      def cleanup_associations
        association_filenames = Dir[@association_dir.join("*").to_s]
        count = 0
        association_filenames.each do |af|
          begin
            f = File.open(af, 'r')
          rescue Errno::ENOENT
            next
          else
            begin
              assoc_s = f.read
            ensure
              f.close
            end
            begin
              association = OpenID::Association.deserialize(assoc_s)
            rescue StandardError
              self.remove_if_present(af)
              next
            else
              if association.expires_in == 0
                self.remove_if_present(af)
                count += 1
              end
            end
          end
        end
        return count
      end

      def cleanup_nonces
        nonces = Dir[@nonce_dir.join("*").to_s]
        now = Time.now.to_i

        count = 0
        nonces.each do |filename|
          nonce = filename.split('/')[-1]
          timestamp = nonce.split('-', 2)[0].to_i(16)
          nonce_age = (timestamp - now).abs
          if nonce_age > Nonce.skew
            self.remove_if_present(filename)
            count += 1
          end
        end
        return count
      end

      protected

      # Create a temporary file and return the File object and filename.
      def mktemp
        f = Tempfile.new('tmp', @temp_dir)
        [f, f.path]
      end

      # create a safe filename from a url
      def filename_escape(s)
        s = '' if s.nil?
        filename_chunks = []
        s.split('').each do |c|
          if @@FILENAME_ALLOWED.index(c)
            filename_chunks << c
          else
            filename_chunks << sprintf("_%02X", c[0])
          end
        end
        filename_chunks.join("")
      end

      def safe64(s)
        s = OpenID::CryptUtil.sha1(s)
        s = OpenID::Util.to_base64(s)
        s.gsub!('+', '_')
        s.gsub!('/', '.')
        s.gsub!('=', '')
        return s
      end

      # remove file if present in filesystem
      def remove_if_present(filename)
        begin
          File.unlink(filename)
        rescue Errno::ENOENT
          return false
        end
        return true
      end

      # ensure that a path exists
      def ensure_dir(dir_name)
        FileUtils::mkdir_p(dir_name)
      end
    end
  end
end

