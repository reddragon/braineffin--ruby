#!usr/bin/env ruby

# bf-ruby.py
# A BrainF**k interpreter in Ruby
# Copyright (C) 2011 Gaurav Menghani <gaurav.menghani@gmail.com>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Usage:
# > ruby bf-ruby.rb bfcode.bf
# Also, you can specify the upper limit on the source size in bytes. By default it is 1MiB
# > ruby bf-ruby.rb bfcode.bf 2097152

class BFRuby
  def getcode
    @code = File.read(@file_name, @source_size)
    raise "File " + @file_name + " was empty"  if @code.empty?
  end
  
  def initialize(file_name, source_size)
    @file_name = file_name
    raise "File not specified" if @file_name.nil?
     
    @source_size = (source_size.nil?) ? 1024 * 1024 : source_size
    raise "Source size should be more than zero. Input: " + @source_size  if @source_size <= 0
    getcode()
    process()
  end
  
  def validate
    # Remove trailing, leading and internal whitespace
    @code.strip.gsub(/ /, "")
    raise "Source does not match the BrainF**k regular expression." unless /\A[><+-.,\[\]]*$/.match(@code)
    bracket = 0
    for i in 0..@code.length-1
      bracket += case @code[i].chr
                   when '[' then 1 
                   when ']' then -1
                   else 0
                 end  
      raise "Mismatched ] at position " + i.to_s if bracket < 0
    end  
      raise bracket.to_s + " mismatched [ in code" if bracket > 0
  end
  
  def process
    validate()
    # Initialize the memory area, occupied memory and current pointer
    @mem = "" + 0.chr
    @mem_occupied = 1
    @mem_curptr = 0
    execute_code
  end
  
  def execute_code
    i = 0
    while i <= @code.length-1
      case @code[i].chr
        when ">" 
          move_ahead
        when "<" 
          move_back
        when "+" 
          increment_value
        when "-" 
          decrement_value
        when "." 
          print_value
        when "["
          ret = open_parantheses(i)
          i = ret unless ret.nil?
        when "]"
          ret = closed_parantheses(i) 
          i = ret unless ret.nil?
      else end
      i = i + 1
    end
  end
  
  def move_ahead
   @mem_curptr += 1
   if @mem_curptr == @mem_occupied
     @mem_occupied += 1
     @mem = @mem + (0.chr)
   end
  end
  
  def move_back
    @mem_curptr -= 1
    if @mem_curptr < 0
      @mem_occupied += 1
      @mem_curptr += 1
      @mem = (0.chr) + @mem
    end
  end
  
  def increment_value
    @mem[@mem_curptr] = ((@mem[@mem_curptr].to_i + 1) % 256).chr
  end
  
  def decrement_value
    @mem[@mem_curptr] = ((@mem[@mem_curptr].to_i - 1) % 256).chr
  end
  
  def print_value
    print @mem[@mem_curptr].chr
  end
  
  def open_parantheses(i)
    if @mem[@mem_curptr].to_i == 0
      bracket = 1
      for j in i + 1 .. @code.length - 1
        bracket += case @code[j].chr
                        when '[' then 1
                        when ']' then -1
                        else 0
                   end
        return j if (code[j] == ']' and bracket == 0)
      end
    end
  end
  
  def closed_parantheses(i)
    if @mem[@mem_curptr].to_i != 0
      bracket = -1
      j = i - 1
      while  j >= 0
        bracket += case @code[j].chr
                        when '[' then 1
                        when ']' then -1
                        else 0
                   end
        return j - 1 if (@code[j].chr == '[' and bracket == 0)
        j = j - 1
      end
    end
  end
  
end

if $__FILE__ = $PROGRAM_NAME
  begin
    # TODO
    # Support long args etc
    # Eg.: bf-ruby.rb sample.bf --source 20000
    # Eg.: bf-ruby.rb sample.bf -s 20000
    # Eg.: bf-ruby.rb sample.bf
    BFRuby.new(ARGV[0], ARGV[1])
    rescue Exception => e
    puts e.message 
  end  
end


