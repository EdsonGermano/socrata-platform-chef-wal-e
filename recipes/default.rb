#
# Cookbook Name:: wal-e
# Recipe:: default

include_recipe "python::pip"

package "python-setuptools"
package "python-dev"
package "lzop"
package "pv"
package "postgresql-client"
package "libevent-dev"
package "daemontools"

python_pip "gevent"
python_pip "argparse"
python_pip "boto"

code_path = "#{Chef::Config[:file_cache_path]}/wal-e"

bash "install_wal_e" do
  cwd code_path
  code <<-EOH
    /usr/bin/python ./setup.py install
  EOH
  action :nothing
end

git code_path do
  repository "https://github.com/wal-e/wal-e.git"
  revision "v0.6.5"
  notifies :run, "bash[install_wal_e]"
end

directory node[:wal_e][:env_dir] do
  user    node[:wal_e][:user]
  group   node[:wal_e][:group]
  mode    "0550"
end

vars = {}
# Make environment configuration backwards compatible
keys = {'WALE_STORAGE_ACCESS_ID' => [:wale_storage_access_id, :aws_access_key],
        'WALE_STORAGE_SECRET_KEY' => [:wale_storage_secret_key, :aws_secret_key],
        'WALE_STORAGE_PREFIX'     => [:wale_storage_prefix, :s3_prefix]}
keys.each do |key, opts|
  opts.each do |opt|
    if node[:wal_e].has_key?(opt)
      vars[key] = node[:wal_e][opt]
    end
  end
end

vars.each do |key, value|
  file "#{node[:wal_e][:env_dir]}/#{key}" do
    content value
    user    node[:wal_e][:user]
    group   node[:wal_e][:group]
    mode    "0440"
  end
end

cron "wal_e_base_backup" do
  user node[:wal_e][:user]
  command "/usr/bin/envdir #{node[:wal_e][:env_dir]} /usr/local/bin/wal-e backup-push #{node[:wal_e][:pgdata_dir]}"

  minute node[:wal_e][:base_backup][:minute]
  hour node[:wal_e][:base_backup][:hour]
  day node[:wal_e][:base_backup][:day]
  month node[:wal_e][:base_backup][:month]
  weekday node[:wal_e][:base_backup][:weekday]
end
