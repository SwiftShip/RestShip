Pod::Spec.new do |s|
  s.name             = "RestShip"
  s.version          = "0.2.2"
  s.summary          = "RestShip is a library for let you easily work with RESTFull Web Applications, sitting on top of Alamofire"

  s.description      = <<-DESC
This library provide a simplify way to access routes to API resources using method chaining and allowing the configuration of requests.
                       DESC

  s.homepage         = "https://github.com/SwiftShip/RestShip"
  s.license          = 'MIT'
  s.author           = { "Diogo Jayme" => "diogojme@gmail.com" , "Italo Sangar" => "itsangardev@gmail.com" }
  s.source           = { :git => "https://github.com/SwiftShip/RestShip.git", :tag => s.version.to_s }

  s.platform     = :ios, '9.0'
  s.requires_arc = true

  s.source_files = 'Source/*'

  s.dependency 'Alamofire'
end
