# 65816 ANS Forth Kernel and Unit Tests

An ITC (Indirect Threaded Code) Forth kernel for the WDC 65816,
targeting a single-board computer with UART serial I/O.

A unit test framework created to ensure correctness of the Forth implementation.

## Architecture

| Property       | Value                          |
|----------------|--------------------------------|
| CPU            | WDC 65816 or 65c265            |
| Standard       | ANS Forth (ANSI 1994)          |
| Threading      | Indirect Threaded Code (ITC)   |
| Cell size      | 16-bit                         |
| ROM            | Kernel ($8000-$FFFF)           |
| RAM            | Stacks, user area, dictionary  |
| I/O            | UART serial                    |

## Directory Structure

```
Claude          summary prompt, cooding sample, and prompt boilerplate.
source          The kernel source.
tests           The test framework and unit tests.
tools           Tools to aid in development.
