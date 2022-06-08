# service-homeassistant

This is an Open Horizon set of configuration to deploy a vanilla instance of the open-source [Home Assistant](https://www.home-assistant.io/getting-started) software.  The Home Assistant UI is designed to run in a web browser, so you will need to navigate to http://localhost:8123/ to use the software once it has been deployed.

## Prerequisites

**Management Hub:** Additionally, you will need to [install the Open Horizon Management Hub](https://open-horizon.github.io/quick-start) or have access to an existing hub in order to publish this service and register your edge node.  You may also choose to use a downstream commercial distribution based on Open Horizon, such as IBM's Edge Application Manager.  If you'd like to use the Open Horizon community hub, you may [apply for a temporary account](https://wiki.lfedge.org/display/LE/Open+Horizon+Management+Hub+Developer+Instance) and have credentials sent to you.

**Edge Node:** You will need an x86 computer running Linux or macOS, or a Raspberry Pi computer (arm64) running Raspberry Pi OS or Ubuntu to install and use Home Assistant deployed by Open Horizon.  You will need to install the Open Horizon agent software, anax, on the edge node and register it with a hub.

## Installation

Clone the `service-homeassistant` GitHub repo from a terminal prompt on the edge node and enter the folder where the artifacts were copied.

  NOTE: This assumes that `git` has been installed on the edge node.

  ``` bash
  git clone https://github.com/open-horizon-services/service-homeassistant.git
  cd service-homeassistant
  ```

Run `make clean` to confirm that the "make" utility is installed and working.

Confirm that you have the Open Horizon agent installed by using the CLI to check the version:

  ``` bash
  hzn verion
  ```

  It should return values for both the CLI and the Agent (actual version numbers may vary from those shown):

  ``` text
  Horizon CLI version: 2.30.0-744
  Horizon Agent version: 2.30.0-744
  ```

  If it returns "Command not found", then the Open Horizon agent is not installed.

  If it returns a version for the CLI but not the agent, then the agent is installed but not running.  You may run it with `systemctl horizon start` on Linux or `horizon-container start` on macOS.

Check that the agent is in an unconfigured state, and that it can communicate with a hub.  If you have the `jq` utility installed, run `hzn node list | jq '.configstate.state'` and check that the value returned is "unconfigured".  If not, running `make agent-stop` or `hzn unregister -f` will put the agent in an unconfigured state.  Run `hzn node list | jq '.configuration'` and check that the JSON returned shows values for the "exchange_version" property, as well as the "exchange_api" and "mms_api" properties showing URLs.  If those do not, then the agent is not configured to communicate with a hub.  If you do not have `jq` installed, run `hzn node list` and eyeball the sections mentioned above.

## Usage

To manually run Home Assistant locally as a test, enter `make`.  This will open a browser window, but it may do so before Home Assistant is completely ready.  If you get a blank web page, wait about 10 seconds or so and reload the page.  When you are done, run `make stop` to end the test.  Running `make attach` will connect you to a prompt running inside the container, and you can exit from that session by entering `exit`.

To create the service definition, publish it to the hub, and then form an agreement to download and run Home Assistant, enter `make publish`.  When installation is complete, you may open a browser pointing to Home Assistant by entering `make browse` or visiting [http://localhost:8123/](http://localhost:8123/) in a web browser.

## Advanced details

### Makefile targets

* `default` - init run browse
* `init` - optionally create the docker volume
* `run` - manually run the homeassistant container locally as a test
* `browse` - open the Home Assistant UI in a web browser
* `check` - view current settings
* `stop` - halt a locally-run container
* `dev` - manually run homeassistant locally and connect to a terminal in the container
* `attach` - connect to a terminal in the homeassistant container
* `test` - request the web UI from the terminal to confirm that it is running and available
* `clean` - remove the container image and docker volume
* `distclean` - clean (see above) AND unregister the node and remove the service files from the hub
* `build` - N/A
* `push` - N/A
* `publish-service` - Publish the service definition file to the hub in your organization
* `publish-deployment-policy` - Publish a deployment for the service to the hub in your org
* `agent-run` - register your agent with the hub
* `publish` - Publish the service, deployment, and then register your agent
* `agent-stop` - unregister your agent with the hub, halting all agreements and stopping containers
* `deploy-check` - confirm that a registered agent is compatible with the service and deployment
* `log` - check the agent event logs

