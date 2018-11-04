#
# Cookbook:: invoicelookup
# Recipe:: default
#
# Copyright:: 2018, The Authors, All Rights Reserved.

chef_gem 'aws-sdk' do
	compile_time true
end

build = node['Java_application']['build']

## Copy file from S3 to C:/temp

s3_file "/home/centos/Simple_Maven_WebApp.1.#{build}.war" do
  source "s3://java-artifacts-formac/#{build}/Simple_Maven_WebApp.1.#{build}.war"
  action :create
  not_if { File.exists?("/home/centos/Simple_Maven_WebApp.1.#{build}.war") }
end

## Deploy LKQ Java_application

bash 'WebApplication_deploy' do
  cwd "/home/centos/"
  code <<-EOH
    /home/centos/apache-tomcat-9.0.10/bin/startup.sh
    cp /home/centos/webapplication.1.*.war /home/centos/apache-tomcat-9.0.10/webapps/
  EOH
end
