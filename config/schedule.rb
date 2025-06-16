# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
set :output, { standard: '/proc/1/fd/1', error: '/proc/1/fd/2' }

job_type :rake, '/rails/bin/cron_executor bundle exec rake :task :output'

# Server is in UTC but I'm on the west coast
every 1.day, at: '12:00pm' do
  rake 'arcdex:pull arcdex:index'
end
