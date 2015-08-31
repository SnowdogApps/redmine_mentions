module RedmineMentions
  module JournalPatch
    def self.included(base)
      base.class_eval do
        after_create :send_notification
        
        def send_notification
          if self.journalized.is_a?(Issue) && self.notes.present?
            issue = self.journalized
            project=self.journalized.project
            users=project.users.to_a.delete_if{|u| (u.type != 'User' || u.mail.empty?)}
            # users_regex=users.collect{|u| "#{Setting.plugin_redmine_mentions['trigger']}#{u.login}"}.join('|')
            users_regex=users.collect{|u| "#{Setting.plugin_redmine_mentions['trigger']}#{u.firstname} #{u.lastname}"}.join('|')
            regex_for_email = '\B('+users_regex+')'
            regex = Regexp.new(regex_for_email)
            mentioned_users = self.notes.scan(regex)
            users = []
            mentioned_users.each do |mentioned_user|
              name = mentioned_user.first[1..-1]
              name_parts = name.split
              users << User.where("firstname = ? and lastname = ?", name_parts[0], name_parts[1]).first
            end
            users.compact.each do |user|
              MentionMailer.notify_mentioning(issue, self.user.login, self.notes, user).deliver
            end
          end
        end
      end
    end
  end
end