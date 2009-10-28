require 'thor'
require 'activerecord'
require 'aws/s3'

class ZfsMysqlBackup < Thor
  no_tasks {
    attr_reader :logger, :connection, :date, :status, :database_yml, :backup_location, :sms_number
  }

  desc "backup path/to/database.yml path/to/backup/dir phone_number_to_sms_if_theres_a_failure [name_of_s3_bucket_here to push to s3]", "Create a zfs backup."
  def backup(database_yml, backup_location, sms_number, s3_bucket = false)
    @database_yml    = database_yml
    @backup_location = backup_location
    @s3_bucket       = s3_bucket
    @sms_number      = sms_number

    init
    acquire_lock
    take_snapshot
    release_lock
    handle_snapshot_result
    push_to_s3 if success? && push_to_s3?
  end
  
  protected 
    def init
      @logger     = Logger.new(STDOUT)
      ActiveRecord::Base.establish_connection(YAML.load(File.read(database_yml))[ENV['RAILS_ENV']])
      @connection = ActiveRecord::Base.connection
    end

    def acquire_lock
      logger.info("[MySQL Backup] Acquiring mysql lock.")
      connection.execute("FLUSH TABLES WITH READ LOCK")
      logger.info("[MySQL Backup] Lock acquired.")
    end

    def take_snapshot
      @date = Time.now.strftime("%d%m%y%H%M")
      logger.info("[MySQL Backup] Creating snapshot at #{date}.")
      system("zfs snapshot data@#{date} 2>&1")
      @status = $?.exitstatus
    end

    def handle_snapshot_result
      success? ? success : failure
    end

    def success
      logger.info("[MySQL Backup] Succeeded! Compressing and exporting to #{path_to_backup}")
      system("zfs send data@#{date} | gzip > #{path_to_backup}")
    end

    def path_to_backup
      "#{backup_location}/mysql-#{date}.gz"
    end

    def failure
      logger.info("[MySQL Backup] FAILED. Notifying the authorities.")
      system(%{echo "MySQL Backup at #{date} FAILED." | /usr/local/bin/send_sms #{sms_number}})
    end

    def release_lock
      logger.info("[MySQL Backup] Unlocking tables")
      connection.execute("UNLOCK TABLES;")
    end

    def push_to_s3?
      @s3_bucket
    end

    def push_to_s3
      logger.info("[MySQL Backup] Pushing to S3 at #{path_to_backup} in #{@s3_bucket}.")
      begin
        AWS::S3::Base.establish_connection! :access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
                                            :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
        AWS::S3::S3Object.store(s3_object_name, open(path_to_backup), @s3_bucket)
      rescue => e
        logger.info("[MySQL Backup] Something went wrong. Notifying the authorities!")
        logger.info("\tError Message #{e.message}")
        system(%{echo "Pushing to S3 at #{date} FAILED." | /usr/local/bin/send_sms #{sms_number}})
      end
      logger.info("[MySQL Backup] Done!")
    end

    def s3_object_name
      hostname = `hostname`
      "mysqlbackups/#{hostname}-#{date}.gz"
    end

    def success?
      status == 0
    end
end
