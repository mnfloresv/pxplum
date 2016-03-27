require 'sinatra/base'

class Pxplum < Sinatra::Base
  configure do
    # Global actions

    # Computer actions
    Pxplum.computer_actions['eject'] = {:label=>'Eject CD', :command=>'eject'}
    Pxplum.computer_actions['beep'] = {:label=>'Beep', :command=>'beep'}
    Pxplum.computer_actions['reboot'] = {:label=>'Reboot', :command=>'/sbin/reboot'}
    Pxplum.computer_actions['poweroff'] = {:label=>'Poweroff', :command=>'/sbin/poweroff'}
    Pxplum.computer_actions['hardware'] = {:label=>'Hardware', :haml=>'hardware'}
  end
end
