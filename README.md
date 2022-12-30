# Microchip Debugger (MDB) Ceedling Plugin

Microchip Debugger (MDB) test fixture for [Ceedling](https://github.com/ThrowTheSwitch/Ceedling).

By default the plugin will override the test fixture tool, taking care of
running the tests with MDB and reporting their output to Ceedling.
You don't have to worry about figuring out how to tell ceedling to run MDB and
grab its output, you just have to add and enable the plugin in your project and
then you can start running your tests with MDB.

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

### Add plugin load path

Add the plugins path to your `project.yml` to tell Ceedling where to find
them if you have not done it yet. Then add `mdb` plugin to the enabled
plugins list:

```yaml
:plugins:
  :load_paths:
    - ~/some/place/for/plugins
```

## Usage

Add `mdb` plugin to the enabled plugins list.

```yaml
:plugins:
  :enabled:
    - mdb
```

make sure the MDB executable is available in your `PATH`.
For example, running

```shell
$ mdb -h
```

whould print out mdb help dialog. *e.g.*:

```
Usage: mdb [options] [commandFile]
Options:
  -h, --help                 Show this help dialog
  -f, --file-name fileName   Set the name of the log file, defaults to "MPLABXlog.xml"
  -d, --log-dir   directory  Set the log output directory, defaults to system TEMP directory
  -l, --log-level logLevel   Set the log level, defaults to INFO

  Log Level options:
    OFF
    SEVERE 
    WARNING 
    INFO -- default
    CONFIG 
    FINE 
    FINER 
    FINEST 
    ALL
```

Add `mdb` section to your `project.yml` and specify the device:

```yaml
:mdb:
  :device: PIC16F84A
```

### Run tests on simulator

By default the plugin will setup MDB to use **sim** as the **hwtool** and to
redirect **UART1** output to *stdout*, so Ceedling can grab the results.

You just run your tests as usually. *e.g.*:

```shell
$ ceedling test:all
```

### Run tests on target

Are you sure?

This require some explaining but also some work by your side.

## Configuration

Add `mdb` section to your `project.yml`. For example, default settings are:

```yaml
:mdb:
  :hwtool: sim
  :hwtools_properties:
    :sim:
      :uart1io.uartioenabled: true
      :uart1io.output: window
```
