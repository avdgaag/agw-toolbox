namespace :agw do
  desc "Clear logs, /tmp and Database session data" 
  task :purge do
    # make sure we don't rid ourselves of the production data
    return unless %w[development test staging].include? RAILS_ENV
    
    ['log:clear', 'tmp:clear', 'db:sessions:clear'].each do |task| 
      puts "Running #{task}..."
      Rake::Task[task].invoke
    end
    puts 'Done!'
  end
end