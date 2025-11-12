# frozen_string_literal: true

module DemoTape
  class TTYD
    attr_reader :pid, :port, :shell, :rcfile

    SHELL_ARGS = {
      "bash" => %w[--norc],
      "zsh" => %w[--no-rcs],
      "fish" => %w[--no-config]
    }.freeze

    def initialize(shell:, port: 0)
      @port = port
      @shell = shell
      @pid = nil
    end

    def shell_args
      SHELL_ARGS.fetch(shell, [])
    end

    def start
      @port = TCPServer.open(0) { it.addr[1] } if port.zero?

      args = [
        "ttyd",
        "--port", port.to_s,
        "--writable",
        "--client-option", "rendererType=canvas",
        "--client-option", "disableResizeOverlay=true",
        "--client-option", "enableSixel=true",
        "--client-option", "customGlyphs=true",
        shell,
        *shell_args
      ]

      @pid = Process.spawn(*args, out: "/dev/null", err: "/dev/null")

      wait_for_port(port, timeout: 5)

      self
    end

    def stop
      return unless pid

      Process.kill("TERM", pid)
      Process.wait(pid)
    rescue Errno::ESRCH, Errno::ECHILD
      # Process already dead
    ensure
      @pid = nil
    end

    def url
      "http://127.0.0.1:#{port}"
    end

    private def wait_for_port(port, timeout:)
      Timeout.timeout(timeout) do
        loop do
          TCPSocket.new("localhost", port).close
          break
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          sleep 0.1
        end
      end
    rescue Timeout::Error
      stop
      raise "ttyd failed to start within #{timeout} seconds"
    end
  end
end
