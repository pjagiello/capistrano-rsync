# obsluga roznych SCM (git/svn/artifactory) na potrzeby capistrano-rsync
# (omija model Capistrano, no ale trudno)

namespace :tsg do
    ########## GIT ##########
    task :git_create_stage do
        sh 'git', 'clone', fetch(:repo_url, "."), fetch(:checkout_dir), '--recursive'
    end

    task :git_stage do
        Dir.chdir(fetch(:checkout_dir)) do
            sh 'git', 'fetch', '--quiet', '--all', '--prune'
            sh 'git', 'reset', '--hard',  "origin/#{fetch(:branch)}"
            sh 'git', 'submodule', 'update', '--init', '--recursive'
        end
        set :rsync_copy_options, fetch(:rsync_copy_options).concat([
            '--exclude=.git',
            '--exclude=.settings',
            '--exclude=.project',
            '--exclude=.buildpath',
            '--exclude=.gitignore'
        ])
    end

    task :git_set_current_revision do
        run_locally do
            within fetch(:checkout_dir) do
                set :current_revision, capture('git', 'rev-parse', '--short', "#{fetch(:branch)}").strip
            end
        end
    end

    ########## ARTIFACTORY ##########
    task :artifactory_create_stage do
        # nic nie rob, pomijamy checkout_dir calkowicie
    end

    task :artifactory_stage do
        server = fetch(:repo_url).sub(/^artifactory@/, '')
        sh 'mkdir', '-p', fetch(:export_dir)
        sh 'wget', '-P', "#{fetch(:export_dir)}", server, "--user=#{fetch(:artlogin)}", "--password=#{fetch(:artpass)}", '--no-proxy' #, '-nv'
        sh 'tar', '-xf', "#{fetch(:export_dir)}/server.tar", '-C', fetch(:export_dir)
        set :rsync_options, fetch(:rsync_options).push("--exclude=server.tar")

    end

    task :artifactory_set_current_revision do
        # (...)
    end

    ########## SVN ##########

    task :svn_create_stage do
        # (...)
    end

    task :svn_stage do
        # (...)
    end

    task :svn_set_current_revision do
        # (...)
    end

end

