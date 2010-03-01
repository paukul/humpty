require 'humpty'

use Rack::Reloader, 0
use Rack::ShowExceptions
use Rack::Lint
run Humpty