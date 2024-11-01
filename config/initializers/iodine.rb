if defined?(Iodine)
  Iodine.threads = ENV.fetch("RAILS_MAX_THREADS", 5).to_i if Iodine.threads.zero?
  Iodine.workers = ENV.fetch("WEB_CONCURRENCY", 2).to_i if Iodine.workers.zero?
  # Iodine::DEFAULT_SETTINGS[:port] ||= ENV.fetch("PORT") if ENV.fetch("PORT")

  Iodine.run_every(4 * 60 * 60 * 1000) do # every 4 hours
    Process.kill("SIGUSR1", Process.pid) unless Iodine.worker?
  end
end
