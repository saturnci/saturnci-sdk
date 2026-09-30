# frozen_string_literal: true

# Publishes the image that every SaturnCI workflow runs in, tagged with this
# repository's SDK version. Tags are immutable: a version that has already been
# published is left alone.
class WorkflowEnvironmentImageBuild
  DOCKERFILE = '.saturnci/jobs/workflow_environment_image_build/Dockerfile'

  class Shell
    def run(command)
      system(command)
    end

    def tag_exists?(image_url)
      system("docker manifest inspect #{image_url} > /dev/null 2>&1")
    end
  end

  def initialize(env:, version:, shell: Shell.new, io: $stdout)
    @env = env
    @version = version
    @shell = shell
    @io = io
  end

  def perform
    return 1 unless log_in

    if @shell.tag_exists?(image_url)
      @io.puts "#{image_url} is already published."
      return 0
    end

    return 1 unless build
    return 1 unless push

    @io.puts "Published #{image_url}."
    0
  end

  private

  def image_url
    "#{@env.fetch('DOCKER_REGISTRY_URL')}/#{@env.fetch('DOCKER_IMAGE_NAME')}:v#{@version}"
  end

  def log_in
    @shell.run(
      "docker login #{@env.fetch('DOCKER_REGISTRY_URL')} " \
      "-u #{@env.fetch('DOCKER_REGISTRY_USERNAME')} " \
      "-p #{@env.fetch('DOCKER_REGISTRY_PASSWORD')}"
    )
  end

  def build
    @shell.run("docker build --platform linux/amd64 -t #{image_url} -f #{DOCKERFILE} .")
  end

  def push
    @shell.run("docker push #{image_url}")
  end
end

exit WorkflowEnvironmentImageBuild.new(env: ENV, version: SaturnCI::VERSION).perform if $PROGRAM_NAME == __FILE__
