module Drunker
  class Source
    attr_reader :target_files

    def initialize(target_dir, logger:)
      @logger = logger
      timestamp = Time.now.to_i.to_s

      @s3 = Aws::S3::Resource.new
      @bucket = s3.create_bucket(bucket: "drunker-source-store-#{timestamp}")
      logger.info("Created source bucket: #{bucket.name}")
      @name = "drunker_source_#{timestamp}.zip"
      @target_files = []

      set_target_files(target_dir)
      archive(target_dir) do |path|
        bucket.object(name).upload_file(path.to_s)
        logger.info("Upload source archive: #{location}")
      end
    end

    def location
      "#{bucket.name}/#{name}"
    end

    def to_h
      {
        type: "S3",
        location: location
      }
    end

    def delete
      bucket.delete!
      logger.info("Deleted bucket: #{bucket.name}")
    end

    private

    attr_reader :s3
    attr_reader :bucket
    attr_reader :name
    attr_reader :logger

    def archive(target_dir)
      archive_path = Pathname.new("#{target_dir.to_s}/#{name}")

      Zip::File.open(archive_path.to_s, Zip::File::CREATE) do |zip|
        Pathname.glob(target_dir.to_s + "/**/*", File::Constants::FNM_DOTMATCH).select(&:file?).each do |real_path|
          archive_file = real_path.relative_path_from(target_dir)
          zip.add(archive_file, real_path.to_s)
          logger.debug("Archived: #{archive_file.to_s}")
        end
      end
      logger.debug("Archived source: #{archive_path.to_s}")
      yield archive_path
      archive_path.unlink
      logger.debug("Deleted archive")
    end

    def set_target_files(target_dir)
      Pathname.glob(target_dir.to_s + "/**/*").select(&:file?).each do |real_path|
        file = real_path.relative_path_from(target_dir).to_s
        @target_files << file
        logger.debug("Set target: #{file}")
      end
    end
  end
end
