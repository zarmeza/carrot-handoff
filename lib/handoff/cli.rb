# frozen_string_literal: true

module Handoff
  # Command line entry point.
  #
  # Commands are intentionally few: save, load, status, agents. Everything runs
  # on plain text on disk, so no agent integration is required to read or write
  # a note.
  class CLI
    USAGE = <<~TEXT.freeze
      handoff — carry a task between agent tools

      Usage:
        handoff save [TASK]   write or update #{Handoff::FILENAME} for the current repo
        handoff load           print the current handoff note
        handoff status         one-line summary, for a quick check
        handoff clear          delete the current handoff note
        handoff path           print the note's absolute path
        handoff help           this message

      In an agent session, start with `handoff load` before working on anything
      a previous session left behind.
    TEXT

    # #run returns a process exit status: 0 on success, 1 on a handled failure.
    def initialize(out: $stdout, err: $stderr)
      @out = out
      @err = err
    end

    COMMANDS = {
      'save' => :save, 'new' => :save,
      'load' => :load, 'show' => :load, 'cat' => :load,
      'status' => :status, 'st' => :status,
      'clear' => :clear, 'rm' => :clear,
      'path' => :path,
      'help' => :help, '-h' => :help, '--help' => :help
    }.freeze

    # #run returns a process exit status: 0 on success, 1 on a handled failure.
    def run(argv)
      name = argv.shift
      return usage(0) if name.nil?

      command = COMMANDS[name]
      return usage(1, "unknown command #{name.inspect}") if command.nil?

      return usage(0) if command == :help

      # `send`, not `public_send`: the command implementations are private, and
      # the only path here is via COMMANDS, which is a closed set.
      send(command, argv)
    rescue Handoff::Error => e
      @err.puts "handoff: #{e.message}"
      1
    end

    def usage(status, error = nil)
      @err.puts "handoff: #{error}" if error
      @err.puts unless error.nil?
      @out.puts USAGE
      status
    end

    private

    def save(argv)
      ensure_repo!

      path = Handoff::Repo.path
      existing = Store.read_or_empty(path)
      task = argv.join(' ').strip

      sections = existing.sections.dup
      sections[:task] = task unless task.empty?

      record = Record.new(sections, path: path)
      Store.write(path, Template.render(record))

      if Git.tracked?(Handoff::FILENAME)
        @out.puts "Wrote #{path} (tracked by git — remember to commit it)"
      else
        @out.puts "Wrote #{path} (untracked — commit it so the next tool sees it)"
      end

      0
    end

    def load(_argv = [])
      ensure_repo!

      unless Handoff::Repo.exists?
        @err.puts "handoff: no #{Handoff::FILENAME} in #{Handoff::Repo.root}"
        @err.puts 'Nothing was handed off yet.'
        return 1
      end

      @out.puts File.read(Handoff::Repo.path)
      0
    end

    def status(_argv = [])
      ensure_repo!

      unless Handoff::Repo.exists?
        @out.puts 'no handoff'
        return 1
      end

      record = Handoff::Repo.current
      task = record.task.strip.lines.first.to_s.strip

      @out.puts "task:     #{task.empty? ? '_(not written)_' : task}"
      @out.puts "file:     #{Handoff::Repo.path}"
      @out.puts "sections: #{written_summary(record)}"
      @out.puts "extra:    #{extra_summary(record)}" unless record.extra_sections.empty?

      0
    end

    # How many sections hold real content, excluding the machine-derived State
    # section and anything still showing its template prompt.
    def written_summary(record)
      human = Record::SECTIONS.keys - [:state]
      written = human.count { |key| !Record::PROMPT_RE.match?(record[key].to_s.strip) && !record[key].strip.empty? }

      "#{written}/#{human.size} written"
    end

    # Custom headings, stripped of the "other_" prefix parse adds.
    def extra_summary(record)
      record.extra_sections.map { |key| key.to_s.sub(/\Aother_/, '') }.join(', ')
    end

    def clear(_argv = [])
      ensure_repo!

      path = Handoff::Repo.path
      unless File.exist?(path)
        @out.puts "nothing to clear (#{path} does not exist)"
        return 0
      end

      File.delete(path)
      @out.puts "Removed #{path}"
      0
    end

    def path(_argv = [])
      ensure_repo!
      @out.puts Handoff::Repo.path
      0
    end

    def ensure_repo!
      Git.reset!
      return if Handoff::Repo.root

      raise Handoff::Error, 'not inside a git repository'
    end
  end
end
