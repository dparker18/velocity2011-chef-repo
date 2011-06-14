#
# Author:: Joshua Timberman <joshua@opscode.com>
# Copyright:: 2011, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

mwhost = "localhost:8080"

%w{ mediawiki-gateway activesupport }.each do |gem|
  gem_package gem do
    action :nothing
  end.run_action(:install)
end

Gem.clear_paths
include_recipe "chef_handler"

ruby_block "update mediawiki Main_Page" do
  block do
    require 'media_wiki'
    mw = MediaWiki::Gateway.new("http://#{mwhost}/api.php")
    mw.edit("Main_Page", "[http://#{node['cloud']['public_hostname']}:8080/status.html Information about this server.]\n\n[[Chef_Run_Status|Last Chef run status]]")
  end
end

chef_handler "MediaWiki::ChefRunStatus" do
  source "#{node['chef_handler']['handler_path']}/mediawiki_handler.rb"
  arguments :url => "http://#{mwhost}/api.php"
  action :nothing
end.run_action(:enable)
