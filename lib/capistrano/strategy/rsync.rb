require File.expand_path('../rsync/version', File.dirname(__FILE__))
require File.expand_path('tsg.rb', File.dirname(__FILE__))

# NOTE: Please don't depend on tasks without a description (`desc`) as they
# might change between minor or patch version releases. They make up the
# private API and internals of Capistrano::Rsync. If you think something should
# be public for extending and hooking, please let me know!

rsync_cache = lambda do
  cache = fetch(:rsync_cache)
  cache = deploy_to + "/" + cache if cache && cache !~ /^\//
  cache
end

# Use cap3's load:defaults to set default vars so that they can be overridden.
namespace :load do
  task :defaults do
    set :rsync_options, %w[--archive --recursive --delete --delete-excluded --exclude .git*]
    set :rsync_copy, "rsync --archive --acls --xattrs"

    # Where on the local machine the build happens. This is where we are
    # rsyncing from.
    #set :build_dir, "_build"

    # Cache is used on the server to copy files to from to the release directory.
    # Saves you rsyncing your whole app folder each time.  If you nil rsync_cache,
    # Capistrano::Rsync will sync straight to the release path.
    set :rsync_cache, "shared/_deploy"
  end
end

Rake::Task["deploy:check"].enhance ["rsync:hook_scm"]
Rake::Task["deploy:updating"].enhance ["rsync:hook_scm"]

desc "Stage and rsync to the server (or its cache)."
task :rsync => %w[rsync:stage] do
  release_roles(:all).each do |role|
    user = role.user + "@" if !role.user.nil?

    rsync_args = []
    rsync_args.concat fetch(:rsync_options)
    rsync_args << fetch(:export_dir) + "/"
    rsync_args << "#{user}#{role.hostname}:#{rsync_cache.call || release_path}"

    sh 'rsync', *rsync_args
  end
end

namespace :rsync do
  task :hook_scm do
    Rake::Task.define_task("#{scm}:check") do
      invoke "rsync:check"
    end

    Rake::Task.define_task("#{scm}:create_release") do
      invoke "rsync:release"
    end
  end

  task :check do
    # Everything's a-okay inherently!
  end

  task :create_stage do
    next if File.directory?(fetch(:checkout_dir))

    invoke "tsg:#{fetch(:repo_type)}_create_stage"
  end

  desc "Stage the repository in a local directory."
  task :stage => %w[create_stage] do
    invoke "tsg:#{fetch(:repo_type)}_stage"
    # kopiujemy z checkout_dir do export_dir
    if File.directory?(fetch(:checkout_dir))
        # folder moze ciagle nie istniec, bo np. artifactory pomija checkout_dir
        sh 'rsync', *(fetch(:rsync_copy_options)), "#{fetch(:checkout_dir)}/", fetch(:export_dir)
    end
  end

  desc "Copy the code to the releases directory."
  task :release => %w[rsync] do
    # Skip copying if we've already synced straight to the release directory.
    next if !fetch(:rsync_cache)

    copy = %(#{fetch(:rsync_copy)} "#{rsync_cache.call}/" "#{release_path}/")
    on release_roles(:all).each do execute copy end
  end

  # Matches the naming scheme of git tasks.
  # Plus was part of the public API in Capistrano::Rsync <= v0.2.1.
  task :create_release => %w[release]

  task :set_current_revision do
    invoke "tsg:#{fetch(:repo_type)}_set_current_revision"
  end
end
