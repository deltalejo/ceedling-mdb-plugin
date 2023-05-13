# Microchip Debugger (MDB) Ceedling Plugin

Add Microchip Debugger (MDB) test fixture to your
[Ceedling](https://github.com/ThrowTheSwitch/Ceedling)
project and run your tests on the simulator (and maybe the target).

## Contents

- [Installation](#installation)
- [Enable the plugin](#enable-the-plugin)
- [Configuration](#configuration)
  - [Basic configuration](#basic-configuration)
  - [Simulator options](#simulator-options)
  - [Breakpoints](#breakpoints)
  - [Timeout](#timeout)
  - [Disable test fixture](#disable-test-fixture)
- [Usage](#usage)
  - [XC8 projects](#xc8-projects)
  - [XC16 projects](#xc16-projects)
  - [XC32 projects](#xc32-projects)
  - [Configuration bits](#configuration-bits)

## Installation

Clone this repo into Ceedling's plugin folder of your current project.
e.g.:

```shell
$ cd <your-project>/vendor/ceedling/plugins
$ git clone https://github.com/deltalejo/ceedling-mdb-plugin.git mdb
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
  :hwtools_properties:
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
    - function name [passCount] # Sets a breakpoint at the beginning of the function.
```

### Timeout

As a safeguard, a timeout can be specified so if the program being run gets
stuck in an endless loop.
e.g.:

```yaml
:mdb:
  :timeout: 10000 # Timeout in milliseconds
```

### Disable test fixture

By default, the plugin overwrites the test fixture tool with its own, so the
tests are run automatically on the simulator. If for some reason tha is not
desired, the test fixture overwrite can be disabled:

```yaml
:mdb:
  :test_fixture: false
```

## Usage

By default the plugin will setup **mdb** to use **sim** (simulator) as the
**hwtool** and to redirect **UART 1** output to *stdout*, so Ceedling can grab
the results.

You just need to run your tests as usually. *e.g.*:

```shell
$ ceedling test:all
```

### XC8 projects

For XC8 projects, extra setup must be carried out so tests output is redirected
to an UART and captured by the simulator.
To achieve this, some test support files need to be created.

Locate the test support directory for your project, e.g. `test/support`, and
create the following files:

##### **`unity_config.h`**
```c
#ifndef UNITY_CONFIG_H
#define UNITY_CONFIG_H

#include "uart.h"

#define UNITY_OUTPUT_START()       uart_init()
#define UNITY_OUTPUT_CHAR(c)       uart_putchar(c)
#define UNITY_OUTPUT_COMPLETE()    uart_deinit()

#endif /* UNITY_CONFIG_H */
```

##### **`uart.h`**
```c
#ifndef UART_H
#define UART_H

void uart_init(void);
void uart_deinit(void);
int uart_putchar(int c);

#endif /* UART_H */
```

##### **`uart.c`**
```c
#include <xc.h>

#include "uart.h"

// Helper function where simulation will end
static void uart_end()
{
  NOP();
}

void uart_init(void)
{
  // Init UART
  // ...
}

void uart_deinit(void)
{
  // Wait for last TX to complete
  // ...
  // De-init UART
  // ...
  
  // Call function in which simulator will halt
  uart_end();
}

int uart_putchar(int c)
{
  // Wait for last TX to complete
  // ...
  // Write next character to TX data register
  // ...
  
  return c;
}

// If you want to use printf() and similar functions, define also the putch()
// function
void putch(char c)
{
  (void) uart_putchar(c);
}
```

Add the test support paths and files to `project.yml`:

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

Set breakpoint on appropriate place so simulation actually halts:

```yaml
:mdb:
  :breakpoints:
    - uart_end
```

### XC16 projects

No known extra steps/setup required.

### XC32 projects

No known extra steps/setup required.

### Configuration bits

Some times it may be needed to set some configuration bits so the simulation
runs properly, for example, disable extended instruction set for PIC18 devices
as the XC8 compiler does not support it.

Locate the test support directory for your project, e.g. `test/support`, and
create a source files where configuration bits will be set:

##### **`config_bits.c`**
```c
// Disable extended instruction set on PIC18 devices
#pragma config XINST = OFF
```

Add the test support path and file to `project.yml`:

```yaml
:paths:
  :support:
    - test/support

:files:
  :support:
    - config_bits.c
```
