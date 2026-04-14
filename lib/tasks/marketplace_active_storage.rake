# frozen_string_literal: true

require "json"
require "fileutils"

namespace :marketplace do
  desc "Re-upload product thumbnails from db/seeds/images when blobs are missing or unreadable (e.g. after switching Disk -> Azure)"
  task repair_seed_thumbnails: :environment do
    images_dir = Rails.root.join("db", "seeds", "images")
    unless images_dir.directory?
      puts "No #{images_dir}; nothing to do."
      next
    end

    fixed = 0
    skipped = 0
    errors = 0

    Product.find_each do |product|
      unless product.thumbnail.attached?
        skipped += 1
        next
      end

      blob = product.thumbnail.blob
      filename = blob.filename.to_s
      seed_path = images_dir.join(filename)

      readable = false
      begin
        product.thumbnail.download
        readable = true
      rescue StandardError => e
        log_repair_event("download_failed", product_id: product.id, filename: filename, error: e.class.name, message: e.message.to_s[0, 200])
      end

      if readable
        skipped += 1
        next
      end

      unless seed_path.file?
        puts "SKIP product #{product.id}: not readable and no seed file #{filename}"
        skipped += 1
        next
      end

      begin
        product.thumbnail.purge
        product.thumbnail.attach(
          io: File.open(seed_path),
          filename: filename,
          content_type: blob.content_type.presence || "image/jpeg"
        )
        fixed += 1
        puts "OK product #{product.id}: re-attached #{filename} -> #{Rails.application.config.active_storage.service}"
        log_repair_event("reattached", product_id: product.id, filename: filename, service: Rails.application.config.active_storage.service.to_s)
      rescue StandardError => e
        errors += 1
        puts "ERR product #{product.id}: #{e.class}: #{e.message}"
        log_repair_event("reattach_failed", product_id: product.id, filename: filename, error: e.class.name, message: e.message.to_s[0, 300])
      end
    end

    summary = { fixed: fixed, skipped: skipped, errors: errors }
    puts "Done: #{summary.inspect}"
    log_repair_event("repair_seed_thumbnails_summary", **summary)
  end
end

def log_repair_event(message, data)
  payload = {
    sessionId: "c5ef7f",
    hypothesisId: "fix-H1",
    location: "marketplace_active_storage.rake",
    message: message,
    data: data,
    timestamp: (Time.now.to_f * 1000).to_i
  }
  line = JSON.generate(payload)
  path = Rails.root.join(".cursor", "debug-c5ef7f.log")
  FileUtils.mkdir_p(File.dirname(path))
  File.open(path, "a") { |f| f.puts(line) }
  Rails.logger.warn("[debug_c5ef7f] #{line}")
rescue StandardError
  nil
end
