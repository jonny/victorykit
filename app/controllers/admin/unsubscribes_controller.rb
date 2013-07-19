class Admin::UnsubscribesController < ApplicationController
  newrelic_ignore
  before_filter :require_admin

  def index
    @unsubscribes = Unsubscribe.
        paginate(:page => params[:page], :per_page => 50).
        order('created_at DESC')
  end

  def new
  end

  def create
    @members_found = 0
    @unsubscribes_created = 0
    @lines = 0

    if params[:file].present?
      upload = params[:file].read
      lines = upload.split("\n")
      lines.each do |line|
        if line.present?
          @lines = @lines +1
          member = Member.first(:conditions => [ "lower(email) = ?", line.downcase ])
          if member
            @members_found = @members_found + 1
            u = Unsubscribe.new(email: line, member: member, cause: 'uploaded')
            @unsubscribes_created =  @unsubscribes_created + 1if u.save
          end
        end
      end
    end
  end

  def export
    if (from = params[:from].try(:to_date)) && (to = params[:to].try(:to_date))
      respond_to do |format|
        format.csv {
          export = Queries::UnsubscribesExport.new(from: from, to: to)
          filename = "#{export.name}-#{Time.now.strftime("%Y%m%d")}.csv"

          self.response.headers['Content-Type'] = 'text/csv'
          self.response.headers['Last-Modified'] = Time.now.ctime.to_s
          self.response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
          self.response_body = export.as_csv_stream
        }
      end
    end
  end

end
