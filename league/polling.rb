#!/usr/bin/env ruby

require 'open-uri'
require 'fileutils'

RegisterURL = 'http://www.paraiso-lang.org/Walpurgisnacht/register.txt'
RegisterFn = 'register.txt'
RegisterFn2 = 'register2.txt'
ResultFn = 'result.txt'
ParticipantsFn = 'participants_yauj.txt'
ParticipantsFn2 = 'participants.txt'
Ptgz = 'p.tgz'

YaujDir = 'yauj/'

ExecMode = ARGV.index('-X')

def sh(str)
  STDERR.puts str
  return system(str)
end



class Participant
  def initialize(n,url)
    @name = n
    @url = url
  end
  attr_accessor :name, :url

  def localdir()
    YaujDir + @name + '/'
  end
  def packagepath()
    localdir() + Ptgz
  end
  def runpath()
    "./yauj_" + name
  end
  def create_runpath()
    open(runpath(), 'w') { |fp|
      fp.puts <<SHELL
#!/bin/sh
cd #{localdir} 
ulimit -t600
./run $@ 
SHELL
    }
    sh "chmod 755 #{runpath()}"
  end
end


yaujParticipants = []




sh "mv #{RegisterFn} #{RegisterFn2}"
sh "wget -T180 -q #{RegisterURL} -O #{RegisterFn}"

if sh("diff #{RegisterFn} #{RegisterFn2}")
  STDERR.puts "register file unchanged!"
  exit 1
end


sh "touch yauj.mutex"

open(RegisterFn, 'r') { |fp|
  counter = 0
  while line = fp.gets
    words = line.split(/\s+/)
    next if words.length < 4
    str = words[0..-4].join(' ')
    name = counter.to_s + "_" + str.gsub(/\W/,'')
    url = words[-1]
    yaujParticipants << Participant::new(name, url)
    counter +=1
  end
}

open(ParticipantsFn,'w') {|fp|
  yaujParticipants.each {|pants|
    fp.puts pants.runpath 
  }
  open(ParticipantsFn2, 'r') {|fp2|
    while line = fp2.gets
      fp.puts line
    end
  }
}

yaujParticipants.each{|pants|
  sh "rm -fr #{pants.localdir}"
  sh "mkdir #{pants.localdir}"
  sh "wget -T180 #{pants.url} -q  -O #{pants.packagepath}"
  STDERR.puts "cd #{pants.localdir}"
  FileUtils.cd(pants.localdir) {
    sh "tar xf #{Ptgz}"
    contents = `tar tf #{Ptgz}`.split(/\n/)
    flag = false
    contents.each{|fn|
      words = fn.split('/')
      if words[-1] == 'install'
        flag = true# found
        if words.length >= 2
          path = words[0..-2].join('/')
          sh "mv #{path}/* ."
        end
        break
      end
    } # end search for
    unless flag
      STDERR.puts "!! cannot recognize package for #{pants.name}"
      next
    end
    sh "chmod 755 install"
    sh "chmod 755 run"

    if ExecMode
      sh "./install" 
    end
  } # exit participant directory
  STDERR.puts "cd ../../"
  if ExecMode
    pants.create_runpath()
  end
} # participant loop


exit 0
