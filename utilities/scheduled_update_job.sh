#exec 1> /home/jnmatias/apps/fbserver/log/crontab.log 2>&1
source /home/jnmatias/.bashrc
export RAILS_ENV="production"
date >> /home/jnmatias/apps/fbserver/log/crontab.log
echo "---------------------" >> /home/jnmatias/apps/fbserver/log/update_user.log
rvm ruby-1.9.3-p385  do ruby /home/jnmatias/apps/fbserver/utilities/update_user_followbias.rb >> /home/jnmatias/apps/fbserver/log/update_user.log
