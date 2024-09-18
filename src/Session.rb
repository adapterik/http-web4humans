require_relative 'SiteDB'

class Session
    def initialize(sid)
        @sid = sid
        @site_db =  SiteDB.new()
        @session_record = nil
        evaluate_session()
    end

    def is_authenticated?()
        not @sid.nil?
    end

    def can_edit?()
      @session_record && @session_record['can_edit'] == 1
    end

    def is_authenticated?() 
      not @session_record.nil?
    end

    def session_id()
      @sid
    end

    def user_id()
      @session_record['user_id'] if not @session_record.nil?
    end

    def get_session_record()
        if @sid.nil?
            return nil
        end

        session_record = @site_db.get_session(@sid)
        now = Time.now.to_i
        if session_record && session_record['expires'] > now
            @site_db.remove_session(@sid)
            @sid = nil
            session_record = nil
        end

        @session_record = session_record
    end

    def evaluate_session() 
        @session_record = get_session_record()
    end
end


