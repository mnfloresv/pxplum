def prettyaddr(addr)
	prefix=addr[0,8]
	file = File.expand_path("oui2.txt", File.dirname(__FILE__))
	vendor = `grep -i #{prefix} #{file} | awk '{print $2}'`.strip
	if vendor.empty?
		addr
	else
		vendor+addr[8,9]
	end
end