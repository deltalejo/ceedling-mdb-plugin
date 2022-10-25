# Microchip Debugger (MDB) Ceedling Plugin

Microchip Debugger (MDB) simulator test fixture for [Ceedling](https://github.com/ThrowTheSwitch/Ceedling).

The plugin automatically add the appropriate test fixture to run tests using MDB
simulator.

## Installation

Create a folder in your machine for Ceedling plugins if you do not have one
already. *e.g.* `~/some/place/for/plugins`:

```shell
$ mkdir -p ~/some/place/for/plugins
```

### Get the plugin

`cd` into the plugins folder and clone this repo:

```shell
$ cd ~/some/place/for/plugins
$ git clone https://github.com/deltalejo/mdb-ceedling-plugin.git mdb
```

### Enable the plugin

Add the plugins path to your `project.yml` to tell Ceedling where to find
them if you have not done it yet. Then add `mdb` plugin to the enabled
plugins list:

```yaml
:plugins:
  :load_paths:
    - ~/some/place/for/plugins
  :enabled:
    - mdb
```

## Usage

Add `mdb` section to your `project.yml` specifyng the path to the MDB executable
and the target device:

```yaml
:mdb:
  :executable: /some/place/in/your/computer/mdb.sh
  :device: PICXXXXXXX
```

Run tests. *e.g.*:

```shell
$ ceedling test:all
```
