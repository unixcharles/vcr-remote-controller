module Rack
  class VcrRemoteController
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["PATH_INFO"] == "/vcr-remote" and VCR
        controller env
      else
        @app.call env
      end
    end

    protected
    def controller(env)
      req = Rack::Request.new(env)
      if req.post?
        VCR.eject_cassette if cassette?
        if req.params['cassette'] == 'create_new_cassette'
          VCR.insert_cassette(req.params["new_cassette_name"], :record => req.params['record_mode'].to_sym)
        else
          VCR.insert_cassette(req.params['cassette'], :record => req.params['record_mode'].to_sym)
        end if req.params['submit'] != 'Eject'
      end
      response
    end

    def cassettes
      Dir["#{VCR::Config.cassette_library_dir}/**/*.yml"].map do |f| 
        f.match(/^#{Regexp.escape(VCR::Config.cassette_library_dir)}\/(.+)\.yml/)[1]
      end
    end

    def current_cassette
      VCR.current_cassette ? VCR.current_cassette.name : nil
    end

    def current_cassette_new_recorded_interactions
      VCR.current_cassette.new_recorded_interactions.map(&:to_yaml).join("\n\n") if cassette?
    end

    def cassette?
      !(VCR.current_cassette == nil)
    end

    def current_cassette_empty?
      VCR.current_cassette.new_recorded_interactions.size == 0 if cassette?
    end

    def current_cassette_record_mode
      VCR.current_cassette.record_mode if cassette?
    end

    def default_record_mode
      VCR::Config.default_cassette_options[:record]
    end

    def current_cassette_status
      if cassette?
        %Q{<p>Current cassette: <b>#{current_cassette}</b> #{ '- (empty)' if current_cassette_empty? }</p>
           <p>Record mode: <b>:#{current_cassette_record_mode}</b></p>}
      else
        '<p>No cassette in the VCR</p>'
      end
    end

    def cassettes_radio_fields
      cassettes.map do |cassette|
        cassette_name = CGI::escapeHTML(cassette)
        selected = current_cassette == cassette
        %Q{<p><label><input type="radio" name="cassette" value="#{cassette_name}"#{' checked' if selected}>#{cassette_name}</label></p>}
      end.join("\n")
    end

    def record_modes_fields
      [:once, :new_episodes, :none, :all].map do |record_mode|
        %Q{<label><input type="radio" name="record_mode" value="#{record_mode}"#{ ' checked' if record_mode == default_record_mode}>:#{record_mode}</label>}
      end.join("\n")
    end

    def new_recored_information
      %Q{<p>New recorded interactions</p>
         <hr/>
         <pre><code>
         #{ CGI::escapeHTML current_cassette_new_recorded_interactions }
         </code></pre>} if cassette? and !(current_cassette_empty?)
    end

    def response
      body = <<-EOF
        <!DOCTYPE html>
        <html>
          <head>
            <title>VCR Remote Controller</title>
          </head>
          <body>
            <h1>VCR Remote Controller</h1> 
              #{current_cassette_status}
            <hr/>
            <form method="post">
              <p>Select a cassettes:</p>
                #{cassettes_radio_fields}
              <p><label><input type="radio" name="cassette" value="create_new_cassette"#{' selected' if current_cassette_empty? or !(cassettes.include?(current_cassette)) }>Create a new cassette</label></p>
              <p><label>New cassette name<input type="text" name="new_cassette_name"></label>
              </p>
              <p>Record mode:</p>
              <p>
                #{record_modes_fields}
              </p>
              <p>
                <input type="submit" name="submit" value="#{'Eject and ' if cassette?}Insert cassette">
                <input type="submit" name="submit" value="Eject">
              </p>
            </form>
            #{new_recored_information}
          </body>
        </html>
        EOF

      [200, {"Content-Type" => "text/html"}, body.gsub(/^ {5}/, "")]
    end
  end
end