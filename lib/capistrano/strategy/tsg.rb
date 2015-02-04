# obsluga roznych SCM (git/svn/artifactory) na potrzeby capistrano-rsync
# (omija model Capistrano, no ale trudno)

namespace :tsg do
  task :hello do
    sh 'echo', 'YO'
  end
end
