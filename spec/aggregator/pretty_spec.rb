require "spec_helper"

RSpec.describe Drunker::Aggregator::Pretty do
  let(:builder1) { double("project_name:builder stub") }
  let(:builder2) { double("project_name:builder stub") }
  let(:builders) { [builder1, builder2] }
  let(:artifact) { double("artifact stub") }
  let(:aggregator) { Drunker::Aggregator::Pretty.new(builders: builders, artifact: artifact) }

  describe "#run" do
    before do
      allow(builder1).to receive(:build_id).and_return("project_name:build_id_1")
      allow(builder2).to receive(:build_id).and_return("project_name:build_id_2")
      allow(builder1).to receive(:success?).and_return(true)
      allow(builder2).to receive(:success?).and_return(false)
      success_body = {
        stdout: "Success!",
        stderr: "warning!",
        exit_status: "0"
      }
      failed_body = {
        stdout: "Trying...",
        stderr: "Failed...",
        exit_status: "1"
      }
      allow(artifact).to receive(:output).and_return("project_name:build_id_1" => success_body, "project_name:build_id_2" => failed_body)
    end

    it "outputs pretty print" do
      output =<<OUTPUT

-------------------------------------------------------------------------------------------
BUILD_ID: project_name:build_id_1
RESULT: SUCCESS
STDOUT: Success!
STDERR: warning!
EXIT_STATUS: 0
-------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------
BUILD_ID: project_name:build_id_2
RESULT: FAILED
STDOUT: Trying...
STDERR: Failed...
EXIT_STATUS: 1
-------------------------------------------------------------------------------------------

OUTPUT
      expect { aggregator.run }.to output(output).to_stdout
    end

    context "when artifact not found" do
      before do
        success_body = {
          stdout: Drunker::Artifact::NOT_FOUND,
          stderr: Drunker::Artifact::NOT_FOUND,
          exit_status: Drunker::Artifact::NOT_FOUND
        }
        failed_body = {
          stdout: Drunker::Artifact::NOT_FOUND,
          stderr: Drunker::Artifact::NOT_FOUND,
          exit_status: Drunker::Artifact::NOT_FOUND
        }
        allow(artifact).to receive(:output).and_return("project_name:build_id_1" => success_body, "project_name:build_id_2" => failed_body)
      end

      it "outputs pretty print" do
        output =<<OUTPUT

-------------------------------------------------------------------------------------------
BUILD_ID: project_name:build_id_1
RESULT: SUCCESS
-------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------
BUILD_ID: project_name:build_id_2
RESULT: FAILED
-------------------------------------------------------------------------------------------

OUTPUT
        expect { aggregator.run }.to output(output).to_stdout
      end
    end
  end

  describe "#exit_status" do
    before do
      success_body = {
        stdout: "Success!",
        stderr: "warning!",
        exit_status: "0"
      }
      failed_body = {
        stdout: "Trying...",
        stderr: "Failed...",
        exit_status: "1"
      }
      allow(artifact).to receive(:output).and_return("project_name:build_id_1" => success_body, "project_name:build_id_2" => failed_body)
    end

    it "returns 1 as exit status code" do
      expect(aggregator.exit_status).to eq 1
    end

    context "when artifact not found" do
      before do
        success_body = {
          stdout: Drunker::Artifact::NOT_FOUND,
          stderr: Drunker::Artifact::NOT_FOUND,
          exit_status: Drunker::Artifact::NOT_FOUND
        }
        failed_body = {
          stdout: Drunker::Artifact::NOT_FOUND,
          stderr: Drunker::Artifact::NOT_FOUND,
          exit_status: Drunker::Artifact::NOT_FOUND
        }
        allow(artifact).to receive(:output).and_return("project_name:build_id_1" => success_body, "project_name:build_id_2" => failed_body)
      end

      it "returns 1 as exit status code" do
        expect(aggregator.exit_status).to eq 1
      end
    end
  end
end
