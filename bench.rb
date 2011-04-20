load "lib/nolate.rb"
require 'benchmark'
require 'tilt'

def bench(descr, times)
    start = Time.now.to_f
    times.times { yield }
    elapsed = Time.now.to_f - start
    reqsec = times / elapsed
    puts "#{descr.ljust(25)}: #{(reqsec).to_i.to_s.rjust(10)} requests/second"
    $template = ""
end

TEMPLATE = <<-TEMPLATE * 3
<html>
<body>
Long template with all the features Yeah!. 2 + 2 is: <%= # 2+2 = 4
2+2
%>

<%= @x %>

<% @x %>

<%#periquin%>

<% (1..2).each{|x| %>
Number <%= x %>
<% } %>

</body></html>
TEMPLATE

TIMES = 30_000

Benchmark.bmbm do |x|
  x.report("empty template")          { TIMES.times { nolate("") } }
  x.report("small constant template") { TIMES.times { nolate("nosub") } }
  x.report("simple substitution")     { TIMES.times { nolate("simple <%= 'sub' %>") } }
  x.report("hash substitution")       { TIMES.times { nolate("hash sub <%#x%>") } }
  x.report("testview2 file template") { TIMES.times { nlt(:testview2) } }
  x.report("big template .nlt") { (TIMES/5).times { @x = 1; nlt(:bigtemplate, :x => 1) } }
  x.report("big template inline") { (TIMES/10).times { @x = 1; nolate(TEMPLATE, :x => 1) } }

  ## Erubis
  v2 = Tilt['erubis'].new('views/testview2.nlt')
  big = Tilt['erubis'].new('views/bigtemplate.erubis')
  x.report("testview2 erubis") { TIMES.times { v2.render(self) } }
  x.report("big template erubis") { (TIMES/5).times { @x = 1; big.render(self, :x => 1, :hash => {}) } }

  ## Verify that the output is the same:
  a = (@x = 1; nlt(:testview2))
  b = v2.render(self)
  warn "testview2 renders differently" if a != b

  a = (@x = 1; nlt(:bigtemplate, :x => 1))
  b = (@x = 1; big.render(self, :x => 1, :hash => {}))
  warn "bigtemplate renders differently" if a != b
end

