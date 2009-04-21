class Gitorial
  # initialize with `git log -p --reverse`, `.git/packed-refs`
  def initialize(gitlogp, commit_link_base="http://github.com/bryanlarsen/agility-gitorial/commit/", tag_refs="")
    @gitlogp=gitlogp
    @commit_link_base=commit_link_base
    @tag_refs=tag_refs
  end

  def tags
    @tags ||= begin
                tags = Hash.new { |hash, key| hash[key]=key.slice(0,6) }
                @tag_refs.slice(1..-1).each {|ref|
                  refs = ref.split
                  tags[refs[0]] = File.basename(refs[1])
                }
                tags
              end
  end

  def to_s
    markdown = []
    state = :message
    message = ["\n"]
    patch = []
    commit = nil
    (@gitlogp.split("\n")+["DONE"]).each { |line|
      words=line.split
      if line.slice(0,1)==" " || words.length==0
        message << "#{line.slice(4..-1)}" if state==:message
        patch << "    #{line}" if state==:patch
      elsif words[0]=="commit" or words[0]=="DONE"
        if !commit.nil?
          # replace the short description line with an a name
          message[2] = "<a name='#{message[2]}'> </a>"
          markdown += message.map {|l|
            if l=="SHOW_PATCH"
              (patch+["{: .diff}\n"]).join("\n")
            else
              l
            end
          }
          markdown << "\n[#{tags[commit]}](#{@commit_link_base}#{commit})\n{: .commit}\n"
        end
        
        message=["\n"]
        patch=[]

        commit = words[1]
        state = :message
      elsif ["Author:", "Date:", "new", "index", "---", "+++", '\\'].include?(words[0])
        # chomp
      elsif words[0]=="diff"
        state = :patch
        left = words[2].slice(2..-1)
        right = words[3].slice(2..-1)
        if left==right
          patch << "    ::: #{right}"
        else
          patch << "    ::: #{left} -> #{right}"
        end
      elsif words[0]=="@@"
        # git tries to put the function or class name after @@. This
        # works great for C diffs, but it only finds the class name in
        # Ruby, which is usually similar to the file name, Therefore
        # it's distracting cruft.  Toss it.
        patch << "    #{words.slice(0,4).join(" ")}"
      else
        message << "#{line.slice(4..-1)}" if state==:message
        patch << "    #{line}" if state==:patch       
      end
    }
    Rails.logger.info(markdown.join("\n"))
    markdown.join("\n")
  end
end
