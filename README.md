# Microchip Debugger (MDB) Ceedling Plugin

Add Microchip Debugger (MDB) test fixture to your
[Ceedling](https://github.com/ThrowTheSwitch/Ceedling)
project and run your tests on the simulator (and maybe the target).

<!-- TOC ignore:true -->
## Contents

<!-- TOC -->

- [Installation](#installation)
- [Enable the plugin](#enable-the-plugin)
- [Configuration](#configuration)
	- [Basic configuration](#basic-configuration)
	- [Simulator options](#simulator-options)
	- [Breakpoints](#breakpoints)
	- [Timeout](#timeout)
	- [Debug tool](#debug-tool)
	- [Serial port](#serial-port)
- [Usage](#usage)
	- [Configuration bits](#configuration-bits)
	- [UART support](#uart-support)
	- [Simulator](#simulator)
	- [Target](#target)
- [Examples](#examples)

<!-- /TOC -->

## Installation

Clone this repo into Ceedling's plugin folder of your current project.
e.g.:

```shell
$ cd <your-project>/vendor/ceedling/plugins
$ git clone https://github.com/deltalejo/ceedling-mdb-plugin.git mdb
```

This plugin requires the [`serialport`](https://rubygems.org/gems/serialport)
gem to be installed.
e.g.:

```shell
$ gem install serialport
```

## Enable the plugin

Add the plugins path to your `project.yml` if you have not done it yet.
Then add **mdb** plugin to the enabled plugins list:

```yaml
:plugins:
  :load_paths:
    - vendor/ceedling/plugins
  :enabled:
    - mdb
```

When the plugin is enabled, it will overwrite test fixture tool with its own, so
the tests are run within MDB.

## Configuration

Add the path where **mdb** executable resides in your system if it is not done
already.
e.g.:

```yaml
:environment:
  - :path:
    - "mplab/installation/path/mplab_platform/bin"
    - "#{ENV['PATH']}"
```

Or alternatively, specify the full path in the `tools` section.
e.g.:

```yaml
:tools:
  :mdb:
    :executable: mplab/installation/path/mplab_platform/bin/mdb.sh
    :arguments:
      - ${1}
```

### Basic configuration

Add `mdb` section to your `project.yml` and specify the target device.
e.g.:

```yaml
:mdb:
  :device: PIC16F84A
```

### Simulator options

Specify simulator options used with the *set* command.

```yaml
:mdb:
  :tools:
    :sim: # 'sim' is the debug tool name given to the hwtool command
      :uart1io.uartioenabled: true # Enable UART 1 I/O
      :uart1io.output: window # Print UART 1 output on console
      # ... more options
```

### Breakpoints

Breakpoints can be specified like it is done directly on **mdb**.
e.g:

```yaml
:mdb:
  :breakpoints:
    - filename:linenumber [passCount] # Sets a breakpoint at the specified source line number.
    - "*address [passCount]" # Sets a breakpoint at an absolute address.
    - function_name [passCount] # Sets a breakpoint at the beginning of the function.
```

### Timeout

As a safeguard, a timeout can be specified so if the program being run gets
stuck in an endless loop.
e.g.:

```yaml
:mdb:
  :timeout: 10000 # Timeout in milliseconds
```

### Debug tool

Specify hardware tool (debugger) to be used to program the target device and run
the tests. Also, set up tool properties used with the *set* command.

```yaml
:mdb:
  :hwtool: snap
  :tools:
    :snap:
      :programoptions.pgmspeed: Max
```

The actual tool used can be overiden from command line.
Properties for all tools that may be used can be specified and the corresponding
ones to the actual tool used will be applied.
e.g.:

```yaml
:mdb:
  :tools:
    :pickit4:
      :programoptions.pgmspeed: Max
    :snap:
      :programoptions.pgmspeed: Max
```

### Serial port

Running tests on target hardware is supported by using a serial port (UART) to
get the results from the target.
As it is usual with this kind of communication,
both sides (host and target) must agreed on the protocol settings to be used.

Specify host side settings. e.g.:

```yaml
---
:mdb:
  :serialport:
    :port: /dev/ttyUSB0 # As this is likely to change, it is recommended to
    # leave this out and instead specify the port from command line.
    :baudrate: 115200 # Default value
    :data_bits: 8 # Default value
    :stop_bits: 1 # Default value
    :parity: :none # Default value
...
```

## Usage

### Configuration bits

Some times it may be needed to set some configuration bits so the tests run
properly, for example, disable extended instruction set for PIC18 devices as the
XC8 compiler does not support it.

Locate the test support directory for your project, e.g. `test/support`, and
create a source files where configuration bits will be set.
e.g.:

##### **`config_bits.c`**
```c
// Disable extended instruction set on PIC18 devices
#pragma config XINST = OFF
```

Add the test support path and file to `project.yml`.
e.g.:

```yaml
:paths:
  :support:
    - test/support

:files:
  :support:
    - config_bits.c
```

### UART support

When using the simulator for XC8 projects or running tests on target hardware,
some extra set up is needed so tests results can be gathered.

Locate the test support directory for your project, e.g. `test/support`, and
create the following files:

##### **`unity_config.h`**
```c
#ifndef UNITY_CONFIG_H
#define UNITY_CONFIG_H

#include "uart.h"

#define UNITY_OUTPUT_START()       uart_start()
#define UNITY_OUTPUT_CHAR(c)       uart_putchar(c)
#define UNITY_OUTPUT_COMPLETE()    uart_stop()

#endif /* UNITY_CONFIG_H */
```

##### **`uart.h`**
```c
#ifndef UART_H
#define UART_H

void uart_start(void);
void uart_stop(void);
int uart_putchar(int c);

#endif /* UART_H */
```

##### **`uart.c`**
```c
#include <stdbool.h>

#include <xc.h>

#include "uart.h"

void uart_end(void);

void uart_start(void)
{
	// Set up device clock
	
	// Set up UART
  
	// Enable UART and TX
}

void uart_stop(void)
{
	// Wait for last TX to complete
	
	// Optionally shutdown the UART
	
	// Breakpoint here to halt the program
	uart_end();
}

void uart_end(void)
{
	while (true);
}

int uart_putchar(int c)
{
	// Wait for UART to be ready to accept more TX data
	
	// Write TX data
	
	return c;
}

// For XC8 projects, define the putch() function if you want to use printf like
// functions.
void putch(char c)
{
	(void) uart_putchar(c);
}
```

Complete the stubs inside `uart.c` accordingly to your target device.

See the [Toolset Customization](https://github.com/ThrowTheSwitch/Unity/blob/master/docs/UnityConfigurationGuide.md#toolset-customization)
section in Unity Configuration Guide for more info.

Add the test support paths and files to `project.yml`.
e.g.:

```yaml
:paths:
  :support:
    - test/support

:files:
  :support:
    - uart.c
```

Tell Unity to use the configuration file:

```yaml
:unity:
  :defines:
    - UNITY_INCLUDE_CONFIG_H
```

Set breakpoint on appropriate place so simulation actually halts.
e.g.:

```yaml
:mdb:
  :breakpoints:
    - uart_end
```

### Simulator

By default the plugin will setup **mdb** to use **sim** (simulator) as the
**hwtool** and to redirect **UART 1** output to *stdout*.

You just need to run your tests as usually. *e.g.*:

```shell
$ ceedling test:all
```

For XC8 projects, extra setup must be carried out so tests output is redirected
to an UART and captured by the simulator.
See [UART support](#uart-support) for more info.

No known extra steps/setup required for XC16. XC-DSC and XXC32 projects.

*Note: If you are using a PIC18 device, you may want to disable extended
instruction set. See [Configuration bits](#configuration-bits) for more info.*

### Target

Are you really sure to go this way?

Running tests on target hardware requires quite bit more setup, you need a
debugger or programming tool to get the tests run on the device but also, at
least, a TX UART pin available to get the tests results.

Refer to the following sections to do the setup required:

- [Debug tool](#debug-tool)
- [Serial port](#serial-port)
- [Configuration bits](#configuration-bits)
- [UART support](#uart-support)

When you are done with all the setup, you can run the tests specifying both the
debug tool to use and the serial port.
e.g.:

```shell
$ ceedling mdb:hwtool[snap] mdb:serialport[/dev/ttyUSB0] test:all
```

And hopefully, if you got the setup right, after a while your tests will run and
you may be able to see the results as normal.

It is possible to omit both `mdb:hwtool[]` and `mdb:serialport[]` tasks from the
command if you have specified them on the configuration file, see
[Debug tool](#debug-tool) and [Serial port](#serial-port) sections.
But as it is likely that those options will change from time to time, it is
recommended to specify them on the command line.

## Examples

Sample projects:

- [XC8](https://github.com/deltalejo/ceedling-microchip-xc8-example).
- [XC16](https://github.com/deltalejo/ceedling-microchip-xc16-example).
- [XC32](https://github.com/deltalejo/ceedling-microchip-xc32-example).
- [XC-DSC](https://github.com/deltalejo/ceedling-microchip-xc-dsc-example).
